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

# double quoted "EOF" for no parameter expansion
cat <<"EOF" >> $DEVSTACK_DIR/local.conf
[[post-config|$NOVA_CONF]]
[DEFAULT]
libvirt_type=qemu
security_group_api=neutron
firewall_driver=nova.virt.firewall.NoopFirewallDriver

EOF

cat <<EOF >> $DEVSTACK_DIR/local.conf
[MIDONET]
midonet_uri = http://$HOST_IP:$MIDONET_API_PORT/midonet-api
username = admin
password = $ADMIN_PASSWORD
project_id = admin
auth_url = http://$KEYSTONE_AUTH_HOST:35357/v2.0
midonet_use_tunctl = True

EOF
