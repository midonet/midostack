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

# Destination directory
DEST=${DEST:-/opt/stack}

source $MIDO_DIR/midonetrc
source $MIDO_DIR/functions

# Reset devstack and Execute stack script
cd $DEVSTACK_DIR && source unstack.sh

# Clean up ZK
stop_service zookeeper
sleep 3
sudo rm -rf /var/lib/zookeeper/*

# Clean up Cassandra
stop_service cassandra
sudo rm -rf /var/lib/cassandra/*

# Shut down midonet screen
MIDO_SCREEN=$(which screen)
if [[ -n "$MIDO_SCREEN" ]]; then
    MIDO_SESSION=$(screen -ls | awk '/[0-9].mido/ { print $1 }')
    if [[ -n "$MIDO_SESSION" ]]; then
        screen -X -S $MIDO_SESSION quit
    fi
fi

# Clean up uplink settings

sudo ip -o link ls | grep veth[0-9a] | cut -d' ' -d':'  -f2 | while read dev ; do sudo ip link del $dev 2> /dev/null ; done
sudo ip link set down uplinkbridge 2> /dev/null
sudo brctl delbr uplinkbridge 2> /dev/null
