#!/bin/bash

if [ $MIDOSTACK_OPENSTACK_BRANCH == "master" ] ; then
    patch -N -d $DEVSTACK_DIR -p1 < $PATCHES_DIR/dont_use_reserved_ports.patch
fi

if [ $MIDOSTACK_NEUTRON_PLUGIN_LOCATION == "upstream" ] ; then
    patch -N -d $DEVSTACK_DIR -p1 < $PATCHES_DIR/upstream_provider_router.patch
fi

if [ $MIDOSTACK_NEUTRON_PLUGIN_LOCATION == "downstream" ] ; then
    if [ $MIDOSTACK_OPENSTACK_BRANCH == "master" ] ; then
        patch -N -d $DEVSTACK_DIR -p1 < $PATCHES_DIR/downstream_plugin_with_juno.patch
    else
        patch -N -d $DEVSTACK_DIR -p1 < $PATCHES_DIR/devstack-use-downstream-neutron-plugin.patch
    fi
fi
