#!/usr/bin/env bash

MIDO_DIR=$(pwd)
DEVSTACK_DIR="$MIDO_DIR/devstack"

source $MIDO_DIR/functions

# Check if devstack script exists
is_devstack_cloned

# Execute stack script
cd $DEVSTACK_DIR && source unstack.sh
