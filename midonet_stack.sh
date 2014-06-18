#!/usr/bin/env bash

export LC_ALL=C
export MIDO_DIR=$(pwd)
export DEVSTACK_DIR="$MIDO_DIR/devstack"
export PRE_DEVSTACK_HOOKS_DIR=$MIDO_DIR/pre_devstack.d
export PATCHES_DIR=$MIDO_DIR/patches

source $MIDO_DIR/functions

# Destination directory
DEST=${DEST:-/opt/stack}

# First configuration file is our own 'localrc'
if [ -f $MIDO_DIR/localrc ]; then
    source $MIDO_DIR/localrc
fi

# Then load the midonetrc
source $MIDO_DIR/midonetrc

# Midonet password. Used to simplify the passwords in the configurated localrc
ADMIN_PASSWORD=${ADMIN_PASSWORD:-$MIDOSTACK_PASSWORD}

# Set fixed and floating range here so we can make sure not to use addresses
# from either range when attempting to guess the IP to use for the host.
# Note that setting FIXED_RANGE may be necessary when running DevStack
# in an OpenStack cloud that uses either of these address ranges internally.
FLOATING_RANGE=${FLOATING_RANGE:-200.200.200.0/24}
PUBLIC_NETWORK_GATEWAY=${PUBLIC_NETWORK_GATEWAY:-200.200.200.1}
FIXED_RANGE=${FIXED_RANGE:-10.0.0.0/24}
FIXED_NETWORK_SIZE=${FIXED_NETWORK_SIZE:-256}

HOST_IP=$(get_default_host_ip $FIXED_RANGE $FLOATING_RANGE "$HOST_IP_IFACE" "$HOST_IP")
if [ "$HOST_IP" == "" ]; then
    die $LINENO "Could not determine host ip address. Either localrc specified dhcp on ${HOST_IP_IFACE} or defaulted"
fi
KEYSTONE_AUTH_HOST=${KEYSTONE_AUTH_HOST:-$HOST_IP}
TOMCAT=${TOMCAT:-tomcat7}


GetDistro

# execute pre devstack hooks
for f in $PRE_DEVSTACK_HOOKS_DIR/* ; do
    test -x $f && {
        echo "Executing " $f
        . $f && echo $f "[OK]" || echo $f "[FAIL]"
    }
done


if [[ "$os_VENDOR" =~ (Red Hat) || "$os_VENDOR" =~ (CentOS) ]]; then
    #Iptables disabled for now
    sudo service iptables stop
    TOMCAT="tomcat6"

elif [[ "$os_VENDOR" =~ (Ubuntu) || "$os_VENDOR" =~ (Debian) ]]; then
    :
else
    echo "Distro not supported."
    exit 1
fi



if [ $BUILD_SOURCES = true ]; then

    :
else
    stop_service $TOMCAT
fi

# Start midonet-api and midolman in a screen
# TODO: Set up midolman.conf properly as well in midolman/conf of Maven.
# Still TODO?? we will see..


# Make sure to load ovs kmod
sudo modprobe openvswitch


MIDONET_API_PORT=${MIDONET_API_PORT:-8081}
MIDONET_API_URI=${MIDONET_API_URI:-http://$HOST_IP:$MIDONET_API_PORT/midonet-api}

if [ $BUILD_SOURCES = true ]; then

    MIDO_SCREEN_EXISTS=$(screen -ls | egrep "[0-9].$MIDONET_SCREEN_NAME")
    if [[ $MIDO_SCREEN_EXISTS == '' ]]; then
        USE_MIDO_SCREEN=$(trueorfalse True $USE_MIDO_SCREEN)
        if [[ "$USE_MIDO_SCREEN" == "True" ]]; then
            # Create a new named screen to run processes in
            screen -d -m -S $MIDONET_SCREEN_NAME -t shell -s /bin/bash
            sleep 1

            # Set a reasonable status bar
            if [ -z "$MIDO_SCREEN_HARDSTATUS" ]; then
                MIDO_SCREEN_HARDSTATUS='%{= .} %-Lw%{= .}%> %n%f %t*%{= .}%+Lw%< %-=%{g}(%{d}%H/%l%{g})'
            fi
            screen -r $MIDONET_SCREEN_NAME -X hardstatus alwayslastline "$MIDO_SCREEN_HARDSTATUS"
            screen -r $MIDONET_SCREEN_NAME -X setenv PROMPT_COMMAND /bin/true
        fi

        # Clear screen rc file
        MIDO_SCREENRC=$MIDO_TOP_DIR/../$MIDONET_SCREEN_NAME-screenrc
        if [[ -e $MIDO_SCREENRC ]]; then
            rm -f $MIDO_SCREENRC
        fi
    else
        echo "You are already running a mido session."
        echo "To rejoin this session type 'screen -x mido'."
        echo "To destroy this session, type './midonet_unstack.sh'."
        exit 1
    fi

    enable_service midolman midonet-api midonet-cp

    # Midolman service must be stopped
    echo "Starting midolman"

    SCREEN_NAME=$MIDONET_SCREEN_NAME
    TOP_DIR=$MIDO_DIR

    screen_it midolman "cd $MIDONET_SRC_DIR && MAVEN_OPTS=\"$MAVEN_OPTS_MIDOLMAN\" mvn -pl midolman exec:exec"
    # Run the API with jetty:plugin
    # Tomcat need to be stopped
    echo "Starting midonet-api"
# put logback.xml to the classpath with "debug" level so mvn jetty:run can pick up
    sed -e 's/info/debug/' \
        -e 's,</configuration>,\
<logger name="org.apache.zookeeper" level="INFO" />\
<logger name="org.apache.cassandra" level="INFO" />\
<logger name="me.prettyprint.cassandra" level="INFO" />\
</configuration>,' \
       $MIDONET_SRC_DIR/midonet-api/conf/logback.xml.sample > \
       $MIDONET_SRC_DIR/midonet-api/target/classes/logback.xml

    screen_it midonet-api "cd $MIDONET_SRC_DIR && MAVEN_OPTS=\"$MAVEN_OPTS_API\" mvn -pl midonet-api jetty:run -Djetty.port=$MIDONET_API_PORT"
    screen_it midonet-cp "cd $MIDONET_CP_DEST && PORT=$MIDONET_CP_PORT grunt server"
    echo "* Making sure MidoNet API server is up and ready."
else
    sudo sed -i -e "s/8080/$MIDONET_API_PORT/g" /etc/$TOMCAT/server.xml
    start_service midolman
    start_service $TOMCAT
fi

STARTUPTIME=0
CONNECTED=1

while [ $CONNECTED -ne 0 ]
  do
    curl -fs $MIDONET_API_URI > /dev/null
    let CONNECTED=$?
    echo "Waiting for API server to start, may take some time. Have waited $STARTUPTIME seconds so far."
    sleep 2
    let STARTUPTIME=STARTUPTIME+2
done

echo "* API server is up, took $STARTUPTIME seconds"

# Execute stack script
cp $MIDO_DIR/devstackrc $DEVSTACK_DIR/local.conf
cd $DEVSTACK_DIR && source stack.sh


# Add a filter to allow rootwrap to use mm-ctl from /usr/local/bin/
sudo cp $MIDO_DIR/config_files/midonet_devstack.filters /etc/nova/rootwrap.d/

if [ -f /etc/libvirt/qemu.conf ]; then

    # Copy the file for backup purposes
    sudo cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.bak

    # Change libvirt config file for qemu to allow "ethernet" mode.
    sudo sed -i -e 's/#user/user/'  -e 's/#group/group/'  -e 's/.*\(clear_emulator_capabilities =\) 1/\1 0/' /etc/libvirt/qemu.conf
    grep  -q '^cgroup_device_acl' /etc/libvirt/qemu.conf | cat <<EOF | sudo tee -a /etc/libvirt/qemu.conf && sudo service libvirt-bin restart
cgroup_device_acl = [
       "/dev/null", "/dev/full", "/dev/zero",
       "/dev/random", "/dev/urandom",
       "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
       "/dev/rtc", "/dev/hpet", "/dev/net/tun",
]

EOF
fi

# Configure midonet-cli
ADMIN_TENANT_ID=$(keystone tenant-list | grep -w admin | awk '{ print $2 }')
MIDONETRC=~/.midonetrc
touch $MIDONETRC
iniset $MIDONETRC cli username "admin"
iniset $MIDONETRC cli password "$ADMIN_PASSWORD"
iniset $MIDONETRC cli project_id "admin"
iniset $MIDONETRC cli api_url "$MIDONET_API_URI"
iniset $MIDONETRC cli tenant "$ADMIN_TENANT_ID"

# To allow connectivity from the host to the 'external' devstack network
# we are going to create the following topology and route the proper
# packages.
#
# 'MidonetProviderRouter' should already have been created.
#
#
#             +---------------+
#                             |
#                             | 172.19.0.1/30
#          +------------------+---------------+
#          |                                  |
#          |     Fakeuplink linux bridge      |
#          |                                  |
#          +------------------+---------------+        'REAL' WORLD
#                             | veth0
#                             |
#                             |
#                             |
# +------+  +-------+  +-------------+  +-----+  +-----+
#                             |
#                             |
#                             |
#               172.19.0.2/30 | veth1
#          +------------------+----------------+        'VIRTUAL' WORLD
#          |                                   |
#          |    MidonetProviderRouter          |
#          |                                   |
#          +------------------+----------------+
#                             |  200.200.200.0/24
#             +               |
#             +---------------+----------------+
#                                        Midostack 'external' network

# 'REAL' WORLD configuration
# clean IP tables first
# sudo iptables -F
# sudo iptables -F -t nat

# create veth interface
sudo ip link add type veth
sudo ip link set dev veth0 up
sudo ip link set dev veth1 up

# create the linux brige, give to it an ip address and attach veth0
sudo brctl addbr uplinkbridge
sudo brctl addif uplinkbridge veth0
sudo ip addr add 172.19.0.1/30 dev uplinkbridge
sudo ip link set dev uplinkbridge up

# allow ip forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# route packets to 'external' network to the bridge
sudo ip route add 200.200.200.0/24 via 172.19.0.2

# 'VIRTUAL' world

PYTHONPATH=/opt/stack/midonet/python-midonetclient/src
# Get MidonetProviderRouter id
PROVIDER_ROUTER_ID=$(/opt/stack/midonet/python-midonetclient/src/bin/midonet-cli -e router list | grep MidonetProviderRouter | awk '{ print$2 }')

# Add a port in the Provider Router id with the IP address 172.19.0.2
PROVIDER_PORT_ID=$(/opt/stack/midonet/python-midonetclient/src/bin/midonet-cli -e router $PROVIDER_ROUTER_ID add port address 172.19.0.2 net 172.19.0.0/30)

# Route any packet to the recent created port
/opt/stack/midonet/python-midonetclient/src/bin/midonet-cli -e router $PROVIDER_ROUTER_ID add route src 0.0.0.0/0 dst 0.0.0.0/0 type normal port router $PROVIDER_ROUTER_ID port $PROVIDER_PORT_ID gw 172.19.0.1

# Create the binding with veth1
HOST_ID=$(/opt/stack/midonet/python-midonetclient/src/bin/midonet-cli -e host list | awk '{print $2 }')
/opt/stack/midonet/python-midonetclient/src/bin/midonet-cli -e host $HOST_ID add binding port router $PROVIDER_ROUTER_ID port $PROVIDER_PORT_ID interface veth1
