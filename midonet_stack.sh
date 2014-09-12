#!/usr/bin/env bash
set -a

MIDOSTACK_TOPDIR=$(cd $(dirname $0) && pwd)
LOGDIR=${MIDOSTACK_LOG_DIR:-$MIDOSTACK_TOPDIR/logs/$(date +'%Y-%m-%d-%H%M%S')}
MIDONET_LOGDIR=$LOGDIR/midonet
DEVSTACK_LOGDIR=$LOGDIR/devstack
mkdir -p $MIDONET_LOGDIR
mkdir -p $DEVSTACK_LOGDIR

set -x
exec 2> $MIDONET_LOGDIR/midonet_stack.sh.stderr.log
echo "Trace log for $0 is at $MIDONET_LOGDIR/midonet_stack.sh.stderr.log"

export LC_ALL=C
export MIDO_DIR=$(pwd)
export DEVSTACK_DIR="$MIDOSTACK_TOPDIR/devstack"
export PRE_DEVSTACK_HOOKS_DIR=$MIDOSTACK_TOPDIR/hooks/pre_devstack.d
export POST_DEVSTACK_HOOKS_DIR=$MIDOSTACK_TOPDIR/hooks/post_devstack.d
export PATCHES_DIR=$MIDOSTACK_TOPDIR/patches

source $MIDOSTACK_TOPDIR/functions

# Destination directory
DEST=${DEST:-/opt/stack}

# First configuration file is our own 'localrc'
if [ -f $MIDOSTACK_TOPDIR/localrc ]; then
    source $MIDOSTACK_TOPDIR/localrc
fi

# Then load the midonetrc
source $MIDOSTACK_TOPDIR/midonetrc

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

function exec_hooks_on_dir() {
    local hook_dir=$1
    for f in $hook_dir/* ; do
	test -x $f && {
            echo -n "Executing $f..."
	    LOGFILE=$MIDONET_LOGDIR/$(basename $f).log
            . $f > $LOGFILE 2>&1  && echo " [OK]" || {
                echo $f " [FAILED]"
                echo "Exiting midostack. Check out the log (also stored in $LOGFILE):"
                echo "========== LOG:"
                cat $LOGFILE
                echo "=== End of LOG ==="
                echo Exiting...
                exit 1
	    }
	}
    done
}


# Parse option parameters
# Default values
MIDOSTACK_NEUTRON_PLUGIN_LOCATION=downstream
MIDONET_GIT_BRANCH=master
MIDONET_CLIENT_BRANCH=master
MIDOSTACK_OPENSTACK_BRANCH=master
MIDOSTACK_OPTION_CHECK=yes
MIDOSTACK_PULL_DEVSTACK=yes
MIDOSTACK_SUPPRESS_MIDO_BRANCH_CHECKS=no

while getopts n:m:c:o:qhBP OPT; do
    case "$OPT" in
      B)
        MIDOSTACK_SUPPRESS_MIDO_BRANCH_CHECKS=yes
        ;;
      n)
        export MIDOSTACK_NEUTRON_PLUGIN_LOCATION=$OPTARG
        ;;
      m)
        export MIDONET_GIT_BRANCH=$OPTARG
        ;;
      c)
        export MIDONET_CLIENT_BRANCH=$OPTARG
        ;;
      o)
        export MIDOSTACK_OPENSTACK_BRANCH=$OPTARG
        export MIDONET_NEUTRON_PLUGIN_GIT_BRANCH=$OPTARG
        ;;
      P)
        MIDOSTACK_PULL_DEVSTACK=no
        ;;
      q)
        export MIDOSTACK_OPTION_CHECK=no
        ;;
      h)
        # got invalid option
        echo 'Usage: $0 [-n neutron_plugin_location] [-m midonet_branch]'
        echo '          [-c midonet_client_branch] [-o openstack_branch ] [-q]'
        echo
        echo '    neutron_plugin_location: Specifies the location of the'
        echo '                             neutron plugin.'
        echo '                             Should be either "upstream" or'
        echo '                             "downstream"'
        echo '                             Default: downstream'
        echo
        echo '    midonet_branch: Specify a branch for midonet'
        echo '                    Default: master'
        echo
        echo '    midonet_client_branch: Specify a branch for python-midonetclient'
        echo '                           Default: master'
        echo
        echo '    openstack_branch: Specify branch for openstack, such as master,'
        echo '                      stable/icehouse.'
        echo '                      Default: master'
        echo
        echo '    -P: Do NOT pull openstack related repos under /opt/stack and'
        echo '        devstack'
        echo
        echo '    -q: quiet mode. With this option, midostack does not prompt'
        echo '         you for confirming branch setup.'
        echo '        Default: off'
        echo
        echo '    -B: suppress branch sanity checks for midokura produced repos. '
        echo '        Useful when used with gerrit, which checks out the code on'
        echo '        anonymoous branch'
        echo '        Default: no'

        exit 0 ;;
    esac
done

echo ========== Running Midostack with the following configuration:
echo Neutron Plugin location: $MIDOSTACK_NEUTRON_PLUGIN_LOCATION
echo MidoNet branch: $MIDONET_GIT_BRANCH
echo MidoNet client branch: $MIDONET_CLIENT_BRANCH
echo OpenStack branch: $MIDOSTACK_OPENSTACK_BRANCH
echo Pull devstack repo: $MIDOSTACK_PULL_DEVSTACK
echo ====================================
if [ "$MIDOSTACK_OPTION_CHECK" == "yes" ] ; then
    echo -n "Confirm the above configuration. Are you sure to proceed? (y/n): "
    read answer
    if [ "$answer" != "y" ] ; then
        echo "exitting..."
        exit 1
    fi
fi

# Check for github accessibility
is_authenticated_to_github
# Sanity check for openstack branches
check_devstack_branch
check_openstack_branch
if [ $MIDOSTACK_SUPPRESS_MIDO_BRANCH_CHECKS != "yes" ] ; then
    check_midonet_branch
    check_python_midonetclient_branch
fi

if [ "$MIDOSTACK_PULL_DEVSTACK" == "yes" ] ; then
    pull_devstack
fi

# Source devstack's functions
source $DEVSTACK_DIR/functions
HOST_IP=$(get_default_host_ip $FIXED_RANGE $FLOATING_RANGE "$HOST_IP_IFACE" "$HOST_IP")
if [ "$HOST_IP" == "" ]; then
    die $LINENO "Could not determine host ip address. Either localrc specified dhcp on ${HOST_IP_IFACE} or defaulted"
fi
KEYSTONE_AUTH_HOST=${KEYSTONE_AUTH_HOST:-$HOST_IP}
GetDistro

echo ====================
echo Running midostack...
echo ====================
echo Log directory: $LOGDIR
echo

echo =================================
echo Executing pre devstack scripts...
echo =================================
exec_hooks_on_dir $PRE_DEVSTACK_HOOKS_DIR



# Temporary Hack to get around SCREEN_NAME nonsense introduced in:
# devstack: d3bf9bdbda9acab17223cf25dd0a2b83b96db522
#  https://review.openstack.org/#/c/117475/
SCREEN_NAME=${SCREEN_NAME:-stack}

LOGFILE=$DEVSTACK_LOGDIR/stack.sh.log
echo ================================================
echo Executing vanilla stack.sh script in devstack...
echo Logfile: $LOGFILE
echo ================================================
cp $MIDOSTACK_TOPDIR/devstackrc $DEVSTACK_DIR/local.conf
cd $DEVSTACK_DIR && ./stack.sh || {
    echo stack.sh failed. Exiting...
    exit 1
}

echo ==================================
echo Executing post devstack scripts...
echo ==================================
exec_hooks_on_dir $POST_DEVSTACK_HOOKS_DIR

echo "Midostack has successfully completed in $SECONDS seconds."
