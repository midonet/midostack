#!/bin/bash -x

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

CASSANDRA_LIST_FILE=/etc/apt/sources.list.d/cassandra.list
if [ ! -f $CASSANDRA_LIST_FILE ]; then
    echo "Adding Cassandra sources"
    echo "deb http://debian.datastax.com/community stable main" | sudo tee $CASSANDRA_LIST_FILE
    curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
fi

sudo cp $MIDO_DIR/config_files/01midokura_apt_preferences /etc/apt/preferences.d/

sudo apt-get -y update
