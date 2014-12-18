#!/bin/bash

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

patch -N -d $DEVSTACK_DIR -p1 < $PATCHES_DIR/dont_use_reserved_ports.patch

if [[ $MIDOSTACK_OPENSTACK_BRANCH == "master" && $MIDOSTACK_NEUTRON_PLUGIN_LOCATION == "downstream" ]] ; then
    patch -N -d $DEVSTACK_DIR -p1 < $PATCHES_DIR/mido_migration.patch
fi

if [ $MIDOSTACK_NEUTRON_PLUGIN_LOCATION == "upstream" ] ; then
    patch -N -d $DEVSTACK_DIR -p1 < $PATCHES_DIR/upstream_provider_router.patch
fi

if [ $MIDOSTACK_NEUTRON_PLUGIN_LOCATION == "downstream" ] ; then
    export DHCP_DRIVER="midonet.neutron.agent.midonet_driver.DhcpNoOpDriver"
    if [ $MIDOSTACK_OPENSTACK_BRANCH == "master" ]  || [ $MIDOSTACK_OPENSTACK_BRANCH == "stable/juno" ] ; then
        patch -N -d $DEVSTACK_DIR -p1 < $PATCHES_DIR/downstream_plugin_with_juno.patch
        patch -N -d $DEVSTACK_DIR -p1 < $PATCHES_DIR/add_extensions_path.patch
    else
        patch -N -d $DEVSTACK_DIR -p1 < $PATCHES_DIR/devstack-use-downstream-neutron-plugin.patch
    fi
fi

if advanced_services_split ; then
    patch -N -d $DEVSTACK_DIR -p1 < $PATCHES_DIR/clone_neutron_lbaas.patch
fi
