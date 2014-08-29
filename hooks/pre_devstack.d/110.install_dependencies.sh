#!/bin/bash
#
# Install dependences
#

sudo apt-get install -y python-dev libxml2-dev libxslt-dev openjdk-7-jdk openjdk-7-jre zookeeper cassandra openvswitch-datapath-dkms linux-headers-`uname -r` maven screen git curl protobuf-compiler

# Trusty requires zookeeperd, but precise does not. The reason is that on
# precise, we install a version of the zookeeper package that contains the
# start up script. This package is not installed on trusty, and trusty
# needs the start up script that comes with zookeeperd
if [ `lsb_release -c | awk '{print $2}'` = "trusty" ]
then
    sudo apt-get install -y zookeeperd
fi
