#!/bin/bash -xe

# To allow connectivity from the host to the 'external' devstack network
# we are going to create the following topology and route the proper
# packages.
#
# 'MidonetProviderRouter' should already have been created.
#
#
#             +---------------+
#                             |
#                             | 172.19.0.1/30
#          +------------------+---------------+
#          |                                  |
#          |     Fakeuplink linux bridge      |
#          |                                  |
#          +------------------+---------------+        'REAL' WORLD
#                             | veth0
#                             |
#                             |
#                             |
# +------+  +-------+  +-------------+  +-----+  +-----+
#                             |
#                             |
#                             |
#               172.19.0.2/30 | veth1
#          +------------------+----------------+        'VIRTUAL' WORLD
#          |                                   |
#          |    MidonetProviderRouter          |
#          |                                   |
#          +------------------+----------------+
#                             |  200.200.200.0/24
#             +               |
#             +---------------+----------------+
#                                        Midostack 'external' network


# create veth interface
sudo ip link add type veth
sudo ip link set dev veth0 up
sudo ip link set dev veth1 up

# create the linux brige, give to it an ip address and attach veth0
sudo brctl addbr uplinkbridge
sudo brctl addif uplinkbridge veth0
sudo ip addr add 172.19.0.1/30 dev uplinkbridge
sudo ip link set dev uplinkbridge up

# allow ip forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# route packets to 'external' network to the bridge
sudo ip route add 200.200.200.0/24 via 172.19.0.2

# 'VIRTUAL' world

$MIDO_DIR/scripts/setup_fake_uplink.sh -a $MIDONET_API_URI -u $MIDONET_USERNAME -p $MIDONET_PASSWORD -i $MIDONET_PROJECT_ID -c $MIDONET_CLIENT_DIR
$MIDO_DIR/scripts/verify_fake_uplink.sh -a $MIDONET_API_URI -u $MIDONET_USERNAME -p $MIDONET_PASSWORD -i $MIDONET_PROJECT_ID -c $MIDONET_CLIENT_DIR

