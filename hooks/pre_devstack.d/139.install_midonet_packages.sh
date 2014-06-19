#!/bin/bash -xe

# Install packages

if [ $BUILD_SOURCES != true ]; then
    if [[ "$os_VENDOR" =~ (Red Hat) || "$os_VENDOR" =~ (CentOS) ]]; then
	sudo yum -y install midonet-api python-midonet-openstack python-midonetclient midolman
    else
	sudo apt-get -y install midonet-api python-midonet-openstack python-midonetclient midolman
    fi
fi
