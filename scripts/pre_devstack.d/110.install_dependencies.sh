#!/bin/bash

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

#
# Install dependences
#

sudo apt-get install -y python-dev libxml2-dev libxslt-dev openjdk-7-jdk openjdk-7-jre maven screen git curl protobuf-compiler

# Trusty requires zookeeperd, but precise does not. The reason is that on
# precise, we install a version of the zookeeper package that contains the
# start up script. This package is not installed on trusty, and trusty
# needs the start up script that comes with zookeeperd
if [ `get_ubuntu_codename` = "trusty" ]; then
    :
else
    sudo apt-get install -y openvswitch-datapath-dkms linux-headers-`uname -r`
fi
