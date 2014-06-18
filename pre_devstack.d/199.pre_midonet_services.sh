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


# Add a filter to allow rootwrap to use mm-ctl from /usr/local/bin/
sudo cp $MIDO_DIR/config_files/midonet_devstack.filters /etc/nova/rootwrap.d/

# Configure libvirt to allow generic ethernet mode

if [ -f /etc/libvirt/qemu.conf ]; then

    # Copy the file for backup purposes
    sudo cp /etc/libvirt/qemu.conf /etc/libvirt/qemu.conf.bak

    # Change libvirt config file for qemu to allow "ethernet" mode.
    sudo sed -i -e 's/#user/user/'  -e 's/#group/group/'  -e 's/.*\(clear_emulator_capabilities =\) 1/\1 0/' /etc/libvirt/qemu.conf
    grep  -q '^cgroup_device_acl' /etc/libvirt/qemu.conf | cat <<EOF | sudo tee -a /etc/libvirt/qemu.conf && sudo service libvirt-bin restart
cgroup_device_acl = [
       "/dev/null", "/dev/full", "/dev/zero",
       "/dev/random", "/dev/urandom",
       "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
       "/dev/rtc", "/dev/hpet", "/dev/net/tun",
]

EOF
fi
