#!/bin/bash -xe

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

# Start Zookeeper

if [ `get_ubuntu_codename` = "trusty" ]; then
    sudo apt-get install -y zookeeper zookeeperd
else
    sudo apt-get install -y zookeeper
fi

stop_service zookeeper
start_service zookeeper
if [ $? -gt 0 ]
then
    echo "Exiting. Zookeeper service failed to start. Check that it has been installed correctly (dpkg -l | grep zookeeper)."
    echo "Otherwise, check if there may be a zombie zookeeper process running (use ps -ef | grep zookeeper)."
    exit 1
fi
