#!/usr/bin/env bash

# Copyright 2014 Midokura SARL
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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

# Stop the services
sudo service cassandra stop
sudo service zookeeper stop

# Install packages
sudo apt-get purge -y python-dev libxml2-dev libxslt-dev openjdk-7-jdk openjdk-7-jre zookeeper zookeeperd cassandra openvswitch-datapath-dkms linux-headers-`uname -r` maven screen
sudo apt-get -y autoremove

# Clean the preferences
RARING_LIST_FILE=/etc/apt/sources.list.d/raring.list
SAUCY_LIST_FILE=/etc/apt/sources.list.d/saucy.list
CASSANDRA_LIST_FILE=/etc/apt/sources.list.d/cassandra.list
MIDOKURA_LIST_FILE=/etc/apt/sources.list.d/midonet.list

sudo rm $RARING_LIST_FILE $SAUCY_LIST_FILE $CASSANDRA_LIST_FILE $MIDOKURA_LIST_FILE

sudo rm /etc/apt/apt.conf.d/01midokura_apt_config
sudo rm /etc/apt/preferences.d/01midokura_apt_preferences

sudo apt-get -y update
