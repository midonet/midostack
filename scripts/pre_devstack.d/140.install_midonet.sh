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

if [ ! -z $MIDOLMAN_PACKAGE_URL ] && [ ! -z $MIDONETAPI_PACKAGE_URL ] ; then

    sudo apt-get install -y bridge-utils haproxy quagga iproute
    wget $MIDOLMAN_PACKAGE_URL -O /tmp/midolman.deb
    wget $MIDONETAPI_PACKAGE_URL -O /tmp/midonet-api.deb
    sudo dpkg -i /tmp/midolman.deb
    sudo dpkg -i /tmp/midonet-api.deb

else

    echo "Building midonet from sources"
    MIDONET_SRC_DIR=$MIDO_DEST/midonet

    # Create the dest dir in case it doesn't exist
    # Github clone will fail to run otherwise
    if [ ! -d $MIDO_DEST ]; then
        echo "Creating midonet destination directory... $MIDO_DEST"
        sudo mkdir -p $MIDO_DEST
        sudo chmod -R 777 $DEST
    fi

    # Get MidoNet source and install
    if [ ! -d "$MIDONET_SRC_DIR" ]; then
        git_clone $MIDONET_GIT_REPO $MIDONET_SRC_DIR $MIDONET_GIT_BRANCH
        if [ $? -gt 0 ]
        then
            echo $?
            echo "Exiting. Cloning MidoNet git repo $MIDONET_GIT_REPO (branch $MIDONET_GIT_BRANCH) failed, please check if environment variable MIDONET_GIT_REPO and MIDONET_GIT_BRANCH."
            exit 1
        fi
    fi
    cd $MIDONET_SRC_DIR && git submodule update --init

    # Build midonet and produce jar files under build directories
    build_midonet

    # install midonet jars and command line tools
    install_midonet
fi

# Clean up previous installation
sudo rm -rf /usr/local/bin/midonet-cli /usr/local/lib/python2.7/dist-packages/midonetclient*

# Install python module and midonet-cli
sudo apt-get install -y ncurses-dev libreadline-dev
sudo pip install -U webob readline httplib2
cd $MIDONET_CLIENT_DIR
sudo python setup.py develop

# Install python midonetcli
if [ -z $MIDONETCLI_PACKAGE_URL ]; then
    git_clone $MIDONET_CLIENT_REPO $MIDONET_CLIENT_DIR $MIDONET_CLIENT_BRANCH
    export PYTHONPATH=$MIDONET_CLIENT_DIR/src:$PYTHONPATH
else
    sudo apt-get install -y libjs-sphinxdoc libjs-underscore python-eventlet python-greenlet python-webob
    wget $MIDONETCLI_PACKAGE_URL -O /tmp/midonet-cli.deb
    sudo dpkg -i /tmp/midonet-cli.deb
fi

