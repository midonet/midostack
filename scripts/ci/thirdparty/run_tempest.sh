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

sudo pip install junitxml

cd /opt/stack/tempest
sudo pip install -r test-requirements.txt

# testtools 1.3.0 breaks everything!
sudo pip uninstall -y testtools
sudo pip install testtools==1.1.0

echo "---------------------- tempest.conf"
cat etc/tempest.conf

#disable IPv6 tests
sed -ri 's/ipv6_subnet_attributes = True/ipv6_subnet_attributes = False/g' /opt/stack/tempest/etc/tempest.conf
sed -ri 's/ipv6 = True/ipv6 = False/g' /opt/stack/tempest/etc/tempest.conf

python -m subunit.run tempest.api.network.test_networks \
tempest.api.network.test_ports \
tempest.api.network.test_networks_negative \
tempest.api.network.test_security_groups \
tempest.api.network.test_security_groups_negative | tee test_results | subunit-2to1 | tools/colorizer.py

subunit2junitxml test_results > ${TEMPEST_XUNIT_FILE:-tempest-results.xml}
