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

MIDONET_CLIENT_DIR=${MIDONET_DIR}/python-midonetclient

# Clean up previous installation
sudo rm -rf /usr/local/bin/midonet-cli /usr/local/lib/python2.7/dist-packages/midonetclient*

# Install python module and midonet-cli
sudo apt-get install -y ncurses-dev libreadline-dev
sudo pip install -U webob readline httplib2
cd $MIDONET_CLIENT_DIR
sudo python setup.py develop

# Make sure to remove system lib dire in case it exists
if grep -qw /usr/lib/python2.7/dist-packages /usr/local/lib/python2.7/dist-packages/easy-install.pth; then
    echo "replacing /usr/local/lib/python2.7/dist-packages/easy-install.pth so it remove /usr/lib/python2.7/dist-packages"
    grep -v /usr/lib/python2.7/dist-packages /usr/local/lib/python2.7/dist-packages/easy-install.pth| sudo tee /usr/local/lib/python2.7/dist-packages/easy-install.pth
fi

