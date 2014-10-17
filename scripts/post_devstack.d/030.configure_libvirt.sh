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
