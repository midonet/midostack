#!/bin/bash -xe
#
# Misc stuff to run before starting MidoNet services
#



if [[ "$os_VENDOR" =~ (Red Hat) || "$os_VENDOR" =~ (CentOS) ]]; then
    #Iptables disabled for now
    sudo service iptables stop
fi

# Make sure to load ovs kmod
sudo modprobe openvswitch
