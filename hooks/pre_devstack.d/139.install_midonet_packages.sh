#!/bin/bash -xe

# Install packages

if [ $BUILD_SOURCES != true ]; then
    sudo apt-get -y install midonet-api python-midonet-openstack python-midonetclient midolman
fi
