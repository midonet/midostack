#!/usr/bin/env bash

MIDO_DIR=$(pwd)
DEVSTACK_DIR="$MIDO_DIR/devstack"
DEST=${DEST:-/opt/stack}

source $MIDO_DIR/functions

# First configuration file is our own 'localrc'
if [ -f $MIDO_DIR/localrc ]; then
    source $MIDO_DIR/localrc
fi

# Execute stack script to clean devstack
cd $DEVSTACK_DIR && source clean.sh

if [ $USE_MIDONET = true ]; then

    sudo rm /etc/nova/rootwrap.d/

    if [ -f /etc/libvirt/qemu.conf ]; then
        sudo rm /etc/libvirt/qemu.conf
        sudo mv /etc/libvirt/qemu.conf.bak /etc/libvirt/qemu.conf
    fi

    echo "Cleaning midonet..."
    # Then load the midonetrc
    source $MIDO_DIR/midonetrc


    # binproxy remove
    sudo rm -rf /usr/local/bin/mm-*

    sudo rm -rf $DEST
    sudo rm -rf $MIDOLMAN_CONF_DIR

    if  [ $BUILD_SOURCES = true ]; then
        # Remove maven repo
        rm -rf ~/.m2/repository/*
        $ZINC_DIR/bin/zinc -shutdown
    fi

    # Stop the services
    sudo service cassandra stop
    sudo service zookeeper stop

    if [[ "$os_VENDOR" =~ (Red Hat) || "$os_VENDOR" =~ (CentOS) ]]; then
        sudo yum remove -y dsc1.1 zookeeper midolman midonet*
    else
        # Install packages
        sudo apt-get purge -y python-dev libxml2-dev libxslt-dev openjdk-7-jdk openjdk-7-jre zookeeper zookeeperd cassandra openvswitch-datapath-dkms linux-headers-`uname -r` maven screen
        sudo apt-get -y autoremove
    
        # Clean the preferences
        RARING_LIST_FILE=/etc/apt/sources.list.d/raring.list
        SAUCY_LIST_FILE=/etc/apt/sources.list.d/saucy.list
        CASSANDRA_LIST_FILE=/etc/apt/sources.list.d/cassandra.list
    
        sudo rm $RARING_LIST_FILE $SAUCY_LIST_FILE $CASSANDRA_LIST_FILE
    
        sudo rm /etc/apt/apt.conf.d/01midokura_apt_config
        sudo rm /etc/apt/preferences.d/01midokura_apt_preferences
    
        sudo apt-get -y update
    fi

fi
