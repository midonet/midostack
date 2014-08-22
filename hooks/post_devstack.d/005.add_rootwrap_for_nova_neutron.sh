#!/bin/bash -xe

sudo cp $MIDO_DIR/config_files/midonet_devstack.filters /etc/nova/rootwrap.d/
sudo cp $MIDO_DIR/config_files/midonet_devstack.filters /etc/neutron/rootwrap.d/
