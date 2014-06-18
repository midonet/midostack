#!/usr/bin/env bash

export LC_ALL=C
export MIDO_DIR=$(pwd)
export DEVSTACK_DIR="$MIDO_DIR/devstack"
export PRE_DEVSTACK_HOOKS_DIR=$MIDO_DIR/hooks/pre_devstack.d
export POST_DEVSTACK_HOOKS_DIR=$MIDO_DIR/hooks/post_devstack.d
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

GetDistro

LOGDIR=$MIDO_DIR/logs/$(date +'%Y-%m-%d-%H:%M:%S')
MIDO_LOGDIR=$LOGDIR/mido
DEVSTACK_LOGDIR=$LOGDIR/devstack
mkdir -p $MIDO_LOGDIR
mkdir -p $DEVSTACK_LOGDIR

function exec_hooks_on_dir() {
    local hook_dir=$1
    for f in $hook_dir/* ; do
	test -x $f && {
            echo -n "Executing $f..."
	    LOGFILE=$MIDO_LOGDIR/$(basename $f).log
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

echo ================================================
echo Executing vanilla stack.sh script in devstack...
echo ================================================
cp $MIDO_DIR/devstackrc $DEVSTACK_DIR/local.conf
cd $DEVSTACK_DIR && source stack.sh > $DEVSTACK_LOGDIR/devstack.log 2>&1

echo ==================================
echo Executing post devstack scripts...
echo ==================================
exec_hooks_on_dir $POST_DEVSTACK_HOOKS_DIR

echo "Midostack has successfully completed in $SECONDS seconds."
