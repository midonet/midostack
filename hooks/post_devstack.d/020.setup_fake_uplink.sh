#!/bin/bash -xe

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
sudo ln -sf /opt/stack/midonet/python-midonetclient/src/bin/midonet-cli /usr/local/bin/midonet-cli

# Get MidonetProviderRouter id
PROVIDER_ROUTER_ID=$(midonet-cli -e router list | grep MidonetProviderRouter | awk '{ print$2 }')

# Add a port in the Provider Router id with the IP address 172.19.0.2
PROVIDER_PORT_ID=$(midonet-cli -e router $PROVIDER_ROUTER_ID add port address 172.19.0.2 net 172.19.0.0/30)

# Route any packet to the recent created port
midonet-cli -e router $PROVIDER_ROUTER_ID add route src 0.0.0.0/0 dst 0.0.0.0/0 type normal port router $PROVIDER_ROUTER_ID port $PROVIDER_PORT_ID gw 172.19.0.1

# Create the binding with veth1
TUNNEL_ZONE_NAME='default_tz'
TUNNEL_ZONE_ID=$(midonet-cli -e create tunnel-zone name $TUNNEL_ZONE_NAME type gre)
echo "Created a new tunnel zone with ID ${TUNNEL_ZONE_ID} and name ${TUNNEL_ZONE_NAME}"

HOST_ID=$(midonet-cli -e host list | awk '{ print $2 }')
midonet-cli -e tunnel-zone $TUNNEL_ZONE_ID add member host $HOST_ID address 172.19.0.2
echo "Added host ${HOST_ID} to the tunnel zone"

# Create the binding with veth1
HOST_ID=$(midonet-cli -e host list | awk '{print $2 }')
midonet-cli -e host $HOST_ID add binding port router $PROVIDER_ROUTER_ID port $PROVIDER_PORT_ID interface veth1

echo "Midostack has successfully completed."
