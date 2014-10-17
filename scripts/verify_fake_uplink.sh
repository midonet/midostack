#!/usr/bin/env bash

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

# Set env variables used in midonet-cli.
while getopts a:u:p:i:c:h: OPT; do
    case "$OPT" in
      a)
        export MIDO_API_URL="$OPTARG" ;;
      u)
        export MIDO_USER="$OPTARG" ;;
      p)
        export MIDO_PASSWORD="$OPTARG" ;;
      i)
        export MIDO_PROJECT_ID="$OPTARG" ;;
      c)
        export PYTHONPATH=$OPTARG/src:$OPTARG/src/bin
        PATH=$PATH:$PYTHONPATH ;;
      h)
        echo "Usage: $0 [-a midonet_api_url] [-u username] [-p password] [-i project_id] [-c client_path]" >&2
        exit 0 ;;
      [?])
        # got invalid option
        echo "KUsage: $0 [-a midonet_api_url] [-u username] [-p password] [-i project_id] [-c client_path]" >&2
        exit 1 ;;
    esac
done
shift $(($OPTIND-1))

PROVIDER_ROUTER_NAME=${PROVIDER_ROUTER_NAME:-'MidoNet Provider Router'}
PROVIDER_ROUTER_ID=${provider_router_id:-$(midonet-cli -e router list | grep "$PROVIDER_ROUTER_NAME" | awk '{ print $2 }')}
if [ ! ${#PROVIDER_ROUTER_ID} -gt 1 ]; then
    echo "FAILED to find provider router"
    exit 1
fi
echo "Found Provider Router with ID ${PROVIDER_ROUTER_ID}"

# ping the provider router interface on the public network. If it succeeds,
# then the public network in openstack has connectivity with this host and
# therefore VMs with floating IPs can access the internet.
RESPONSE=$(ping -W 250 -c 1 200.200.200.1 | grep "1 received")
if [ ! ${#RESPONSE} -gt 1 ]; then
    echo "FAILED to ping the provider router"
    exit 1
fi
echo "The fake uplink has been set up successfully"
