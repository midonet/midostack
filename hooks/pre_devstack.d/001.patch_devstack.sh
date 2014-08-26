#!/bin/bash

if [ $MIDOSTACK_NEUTRON_PLUGIN_LOCATION == "downstream" ] ; then
    patch -N -d $DEVSTACK_DIR -p1 < $PATCHES_DIR/devstack-use-downstream-neutron-plugin.patch
else
    cd $DEVSTACK_DIR
    git reset --hard
    cd - > /dev/null
fi
