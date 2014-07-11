#!/usr/bin/env bash
set -a
set -x

MIDOSTACK_TOPDIR=$(cd $(dirname $0) && pwd)
LOGDIR=${MIDOSTACK_LOG_DIR:-$MIDOSTACK_TOPDIR/logs/$(date +'%Y-%m-%d-%H%M%S')}
MIDONET_LOGDIR=$LOGDIR/midonet
DEVSTACK_LOGDIR=$LOGDIR/devstack
mkdir -p $MIDONET_LOGDIR
mkdir -p $DEVSTACK_LOGDIR

exec 2> $MIDONET_LOGDIR/midonet_stack.sh.stderr.log

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

HOST_IP=$(get_default_host_ip $FIXED_RANGE $FLOATING_RANGE "$HOST_IP_IFACE" "$HOST_IP")
if [ "$HOST_IP" == "" ]; then
    die $LINENO "Could not determine host ip address. Either localrc specified dhcp on ${HOST_IP_IFACE} or defaulted"
fi
KEYSTONE_AUTH_HOST=${KEYSTONE_AUTH_HOST:-$HOST_IP}

GetDistro


function exec_hooks_on_dir() {
    local hook_dir=$1
    for f in $hook_dir/* ; do
	test -x $f && {
            echo -n "Executing $f..."
	    LOGFILE=$MIDONET_LOGDIR/$(basename $f).log
            . $f > $LOGFILE 2>&1  && echo " [OK]" || {
		echo $f " [FAILED]"
		echo "Exiting midostack. Check out the log file: $LOGFILE"
		exit 1
	    }
	}
    done
}

echo ====================
echo Running midostack...
echo ====================
echo Log directory: $LOGDIR
echo

echo =================================
echo Executing pre devstack scripts...
echo =================================
exec_hooks_on_dir $PRE_DEVSTACK_HOOKS_DIR


LOGFILE=$DEVSTACK_LOGDIR/stack.sh.log
echo ================================================
echo Executing vanilla stack.sh script in devstack...
echo Logfile: $LOGFILE
echo ================================================
cp $MIDOSTACK_TOPDIR/devstackrc $DEVSTACK_DIR/local.conf
cd $DEVSTACK_DIR && ./stack.sh

# save vanilla devstack logs

# Copy devstack service logs
mkdir -p $DEVSTACK_LOGDIR/services
cp $(find /tmp/ -type l) $DEVSTACK_LOGDIR/services


echo ==================================
echo Executing post devstack scripts...
echo ==================================
exec_hooks_on_dir $POST_DEVSTACK_HOOKS_DIR

echo "Midostack has successfully completed in $SECONDS seconds."
