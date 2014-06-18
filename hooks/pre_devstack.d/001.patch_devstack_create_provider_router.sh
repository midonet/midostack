#!/bin/bash 

patch -N -d $DEVSTACK_DIR -p1 < $PATCHES_DIR/devstack-provider-router.patch 
