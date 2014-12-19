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

if [ "$BUILD_SOURCES" = "true" ]; then
    MIDONET_PLUGIN_SRC_DIR=$MIDONET_DIR/python-neutron-plugin-midonet
    if [ ! -d "$MIDONET_PLUGIN_SRC_DIR" ]; then
        git_clone $MIDONET_NEUTRON_PLUGIN_GIT_REPO $MIDONET_PLUGIN_SRC_DIR  $MIDONET_NEUTRON_PLUGIN_GIT_BRANCH
    fi

    # install the executables to /usr/local
    cd $MIDONET_PLUGIN_SRC_DIR
    sudo python setup.py develop
    cd -

    # clean up easy-install.pth
    grep -v /usr/lib/python2.7 /usr/local/lib/python2.7/dist-packages/easy-install.pth| sudo tee /usr/local/lib/python2.7/dist-packages/easy-install.pth
else
    echo "BUILD_SOURCES false not supported"
    return 0
fi
