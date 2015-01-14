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

if [ $MIDONET_GIT_BRANCH == "master" ] ; then
    if ! which protoc > /dev/null || [ "$(protoc --version | awk '{print $2}')" != "2.6.1" ]; then
        wget https://github.com/google/protobuf/releases/download/v2.6.1/protobuf-2.6.1.tar.gz
        tar -xzf protobuf-2.6.1.tar.gz
        cd protobuf-2.6.1
        ./configure
        make
        sudo make install
        sudo ldconfig
        cd -
        rm -rf protobuf-2.6.1
        rm protobuf-2.6.1.tar.gz
    fi
fi
