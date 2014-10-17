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

# apt package pinning (zookeeper 3.4.5, ovs-dp 1.10)
UBUNTU_ARCHIVE="http://us.archive.ubuntu.com/ubuntu/"
SAUCY_SRC="deb $UBUNTU_ARCHIVE saucy universe\ndeb-src $UBUNTU_ARCHIVE saucy universe"
SAUCY_LIST_FILE=/etc/apt/sources.list.d/saucy.list
if [ ! -f $SAUCY_LIST_FILE ]; then
    echo "Adding sources from Ubuntu Saucy release"
    echo -e $SAUCY_SRC | sudo tee $SAUCY_LIST_FILE
fi
CASSANDRA_LIST_FILE=/etc/apt/sources.list.d/cassandra.list
if [ ! -f $CASSANDRA_LIST_FILE ]; then
    echo "Adding Cassandra sources"
    if  [ `get_ubuntu_codename` == "trusty" ]; then
        echo "deb http://debian.datastax.com/community stable main" | sudo tee $CASSANDRA_LIST_FILE
        curl -L http://debian.datastax.com/debian/repo_key | sudo apt-key add -
    else
        echo -e 'deb http://www.apache.org/dist/cassandra/debian 11x main\ndeb-src http://www.apache.org/dist/cassandra/debian 11x main' | sudo tee $CASSANDRA_LIST_FILE
        sudo gpg --keyserver pgp.mit.edu --recv-keys F758CE318D77295D
        sudo gpg --export --armor F758CE318D77295D | sudo apt-key add -
        sudo gpg --keyserver pgp.mit.edu --recv-keys 2B5C1B00
        sudo gpg --export --armor 2B5C1B00 | sudo apt-key add -
    fi
fi

sudo cp $MIDO_DIR/config_files/01midokura_apt_preferences /etc/apt/preferences.d/


# Add Midokura Repository
MIDONET_SRC="deb [trusted=1 arch=amd64] http://$MIDO_APT_USER:$MIDO_APT_PASSWORD@apt.midokura.com/midonet/$PKG_MAJOR_VERSION/$PKG_STATUS_VERSION $PKG_OS_RELEASE main non-free test"
MIDONET_LIST_FILE=/etc/apt/sources.list.d/midonet.list
if [ ! -f $MIDONET_LIST_FILE ]; then
    echo "Adding sources from Midonet package daily"
    echo -e $MIDONET_SRC | sudo tee $MIDONET_LIST_FILE
fi
# Download and install Midokura public key to validate software authenticity
curl -k http://$MIDO_APT_USER:$MIDO_APT_PASSWORD@apt.midokura.com/packages.midokura.key | sudo apt-key add -

sudo apt-get -y update
