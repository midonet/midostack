#!/bin/bash 

for p in $PATCHES_DIR/devstack-*.patch ; do
    patch -N -d $DEVSTACK_DIR -p1 < $p
done
