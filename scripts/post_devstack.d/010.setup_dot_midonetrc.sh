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

# Configure midonet-cli
ADMIN_TENANT_ID=$(keystone tenant-list | grep -w admin | awk '{ print $2 }')
MIDONETRC=~/.midonetrc
touch $MIDONETRC
iniset $MIDONETRC cli username "admin"
iniset $MIDONETRC cli password "$ADMIN_PASSWORD"
iniset $MIDONETRC cli project_id "admin"
iniset $MIDONETRC cli api_url "$MIDONET_API_URI"
iniset $MIDONETRC cli tenant "$ADMIN_TENANT_ID"
