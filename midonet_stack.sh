#!/usr/bin/env bash

MIDO_DIR=$(pwd)
DEVSTACK_DIR="$MIDO_DIR/devstack"

source $MIDO_DIR/functions

# Check if devstack script exists
is_devstack_cloned

# Midonet password. Used to simplify the passwords in the configurated localrc
MIDOSTACK_PASSWORD=${MIDOSTACK_PASSWORD:-gogomid0}

# Setting this value as 'false' will deploy a devstack with quantum and openvsitch
USE_MIDONET=${USE_MIDONET:-true}

# Destination directory
DEST=${DEST:-/opt/stack}

# First configuration file is our own 'localrc'
if [ -f $MIDO_DIR/localrc ]; then
    source $MIDO_DIR/localrc
fi

if [ $USE_MIDONET = true ]; then
    MIDO_DEST=$DEST/midonet
fi

# Execute stack script
cp $MIDO_DIR/midonetrc $DEVSTACK_DIR/localrc
cd $DEVSTACK_DIR && source stack.sh
