#!/bin/bash

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
