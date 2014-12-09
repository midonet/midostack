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

if use_midonet_sources ; then
    # Set up web.xml for midonet-api
    MIDONET_API_CFG=$MIDONET_SRC_DIR/midonet-api/src/main/webapp/WEB-INF/web.xml
else
    sudo apt-get install -y tomcat7
    # Set up web.xml for midonet-api
    MIDONET_API_CFG=/usr/share/midonet-api/WEB-INF/web.xml
fi


sudo cp $MIDONET_API_CFG.dev $MIDONET_API_CFG
sudo cp $MIDONET_API_CFG.dev $MIDONET_API_CFG.bak
# TODO(ryu): Improve this part
sudo sed -i -e "s/999888777666/$PASSWORD/g" $MIDONET_API_CFG
sudo sed -i -e "s/mido_admin/admin/g" $MIDONET_API_CFG
sudo sed -i -e "s/mido_tenant_admin/Member/g" $MIDONET_API_CFG
sudo sed -i -e "s/mido_tenant_user/Member/g" $MIDONET_API_CFG

if [ $MIDONET_API_USE_KEYSTONE = true ]; then
    sudo sed -i -e "s/org.midonet.api.auth.MockAuthService/org.midonet.api.auth.keystone.v2_0.KeystoneService/g" $MIDONET_API_CFG
fi
sudo sed -i -e "/<param-name>keystone-service_host<\/param-name>/{n;s%.*%    <param-value>$KEYSTONE_AUTH_HOST</param-value>%g}" $MIDONET_API_CFG
sudo sed -i -e "/<param-name>keystone-admin_token<\/param-name>/{n;s%.*%    <param-value>$ADMIN_PASSWORD</param-value>%g}" $MIDONET_API_CFG
sudo sed -i -e "/<param-name>rest_api-base_uri<\/param-name>/{n;s%.*%    <param-value>http://$HOST_IP:$MIDONET_API_PORT/midonet-api</param-value>%g}" $MIDONET_API_CFG
