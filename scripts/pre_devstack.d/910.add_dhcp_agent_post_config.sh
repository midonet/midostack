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

cat <<"EOF" >> $DEVSTACK_DIR/local.conf
[[post-config|$Q_DHCP_CONF_FILE]]
[DEFAULT]
interface_driver = neutron.agent.linux.interface.MidonetInterfaceDriver

EOF

cat <<EOF >> $DEVSTACK_DIR/local.conf
[MIDONET]
midonet_uri = $MIDONET_API_URI
username = $MIDONET_USERNAME
password = $MIDONET_PASSWORD
project_id = $MIDONET_PROJECT_ID

EOF
