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

PYTHONPATH=/opt/stack/tempest nosetests -vv tempest.api.network.admin.test_agent_management \
tempest.api.network.admin.test_external_network_extension \
tempest.api.network.test_networks:BulkNetworkOpsTestJSON.test_bulk_create_delete_network \
tempest.api.network.test_networks:BulkNetworkOpsTestJSON.test_bulk_create_delete_subnet \
tempest.api.network.test_networks:BulkNetworkOpsTestXML.test_bulk_create_delete_network \
tempest.api.network.test_networks:BulkNetworkOpsTestXML.test_bulk_create_delete_subnet \
tempest.api.network.test_networks:NetworksTestJSON.test_create_delete_subnet_with_gw \
tempest.api.network.test_networks:NetworksTestJSON.test_create_delete_subnet_without_gw \
tempest.api.network.test_networks:NetworksTestJSON.test_create_update_delete_network_subnet \
tempest.api.network.test_networks:NetworksTestJSON.test_delete_network_with_subnet \
tempest.api.network.test_networks:NetworksTestJSON.test_list_networks \
tempest.api.network.test_networks:NetworksTestJSON.test_list_networks_fields \
tempest.api.network.test_networks:NetworksTestJSON.test_list_subnets \
tempest.api.network.test_networks:NetworksTestJSON.test_list_subnets_fields \
tempest.api.network.test_networks:NetworksTestJSON.test_show_network \
tempest.api.network.test_networks:NetworksTestJSON.test_show_network_fields \
tempest.api.network.test_networks:NetworksTestJSON.test_show_subnet \
tempest.api.network.test_networks:NetworksTestJSON.test_show_subnet_fields \
tempest.api.network.test_networks:NetworksTestXML.test_create_delete_subnet_with_gw \
tempest.api.network.test_networks:NetworksTestXML.test_create_delete_subnet_without_gw \
tempest.api.network.test_networks:NetworksTestXML.test_create_update_delete_network_subnet \
tempest.api.network.test_networks:NetworksTestXML.test_delete_network_with_subnet \
tempest.api.network.test_networks:NetworksTestXML.test_list_networks \
tempest.api.network.test_networks:NetworksTestXML.test_list_networks_fields \
tempest.api.network.test_networks:NetworksTestXML.test_list_subnets \
tempest.api.network.test_networks:NetworksTestXML.test_list_subnets_fields \
tempest.api.network.test_networks:NetworksTestXML.test_show_network \
tempest.api.network.test_networks:NetworksTestXML.test_show_network_fields \
tempest.api.network.test_networks:NetworksTestXML.test_show_subnet \
tempest.api.network.test_networks:NetworksTestXML.test_show_subnet_fields \
tempest.api.network.test_networks_negative \
tempest.api.network.test_security_groups \
tempest.api.network.test_security_groups_negative \
--with-xunit --xunit-file=${TEMPEST_XUNIT_FILE:-tempest-results.xml}
