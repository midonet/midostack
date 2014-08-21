#!/bin/bash -xe

if [ "$BUILD_SOURCES" = "true" ]; then
    MIDONET_PLUGIN_SRC_DIR=$MIDO_DEST/python-neutron-plugin-midonet
    if [ ! -d "$MIDONET_PLUGIN_SRC_DIR" ]; then
        git_clone $MIDONET_NEUTRON_PLUGIN_GIT_REPO $MIDONET_PLUGIN_SRC_DIR  $MIDONET_NEUTRON_PLUGIN_GIT_BRANCH
    fi
    export PYTHONPATH=$MIDONET_CLIENT_DIR/src:$MIDONET_CLIENT_DIR/src/bin:$MIDONET_PLUGIN_SRC_DIR
else
    echo "BUILD_SOURCES false not supported"
    return 0
fi
