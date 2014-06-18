#!/bin/bash
#
# Install dependences
#

if [[ "$os_VENDOR" =~ (Red Hat) || "$os_VENDOR" =~ (CentOS) ]]; then

    sudo yum install -y dsc1.1 zookeeper screen git curl java-1.7.0-openjdk  python-setuptools dbus gcc python-devel libxslt-devel libxml2-devel
    # RHEL does not provide this package, installing directly from centos
    sudo yum install -y http://mirror.centos.org/centos-6/6/os/x86_64/Packages/libffi-devel-3.0.5-3.2.el6.x86_64.rpm

elif [[ "$os_VENDOR" =~ (Ubuntu) || "$os_VENDOR" =~ (Debian) ]]; then

    sudo apt-get install -y python-dev libxml2-dev libxslt-dev openjdk-7-jdk openjdk-7-jre zookeeper zookeeperd cassandra openvswitch-datapath-dkms linux-headers-`uname -r` maven screen git curl

fi
