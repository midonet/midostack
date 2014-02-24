#!/usr/bin/env bash

CURRENT_DIR=$(pwd)
DEVSTACK_DIR="$CURRENT_DIR/devstack"

# Check if devstack script exists
if [ ! -f "$DEVSTACK_DIR/stack.sh" ]; then
    echo "$DEVSTACK_DIR/stack.sh does not exist. "
    echo "You problably haven't cloned devstack yet. "
    echo "Execute 'git submodule update --init' to clone devstack and run this script again"
    exit 1;
fi

# Execute stack script
cd $DEVSTACK_DIR && source stack.sh
