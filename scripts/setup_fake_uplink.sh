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

export MIDO_TENANT=

# Get MidonetProviderRouter id.
PROVIDER_ROUTER_ID=${provider_router_id:-$(midonet-cli -e router list | grep "MidoNet Provider Router" | awk '{ print $2 }')}
if [ ! ${#PROVIDER_ROUTER_ID} -gt 1 ]; then
    echo "FAILED to find provider router"
    exit 1
fi
echo "Found Provider Router with ID ${PROVIDER_ROUTER_ID}"

# Add a port in the Provider Router id with the IP address 172.19.0.2
PROVIDER_PORT_ID=$(midonet-cli -e router $PROVIDER_ROUTER_ID add port address 172.19.0.2 net 172.19.0.0/30)
if [ ! ${#PROVIDER_PORT_ID} -gt 1 ]; then
    echo "FAILED to create port on provider router"
    exit 1
fi
echo "Found Provider Router Port with ID ${PROVIDER_PORT_ID}"

# Route any packet to the recent created port
ROUTE=$(midonet-cli -e router $PROVIDER_ROUTER_ID add route src 0.0.0.0/0 dst 0.0.0.0/0 type normal port router $PROVIDER_ROUTER_ID port $PROVIDER_PORT_ID gw 172.19.0.1)
if [ ! ${#ROUTE} -gt 1 ]; then
    echo "FAILED to create route on provider router"
    exit 1
fi
echo "Created Route on provider router with ID ${ROUTE}"

# Create a tunnel zone for this host
TUNNEL_ZONE_NAME='default_tz'
TUNNEL_ZONE_ID=$(midonet-cli -e create tunnel-zone name $TUNNEL_ZONE_NAME type gre)
if [ ! ${#TUNNEL_ZONE_ID} -gt 1 ]; then
    echo "FAILED to create tunnel zone"
    exit 1
fi
echo "Created a new tunnel zone with ID ${TUNNEL_ZONE_ID} and name \
      ${TUNNEL_ZONE_NAME}"

# Get our host id
HOST_ID=$(midonet-cli -e host list | awk '{ print $2 }')
if [ ! ${#HOST_ID} -gt 1 ]; then
    echo "FAILED to obtain host id"
    exit 1
fi
echo "Found host with id ${HOST_ID}"

# add our host as a member to the tunnel zone
MEMBER=$(midonet-cli -e tunnel-zone $TUNNEL_ZONE_ID add member host $HOST_ID address 172.19.0.2)
if [ ! ${#MEMBER} -gt 1 ]; then
    echo "FAILED to create tunnel zone member"
    exit 1
fi
echo "Added member ${MEMBER} to the tunnel zone"

# Create the binding with veth1
BINDING=$(midonet-cli -e host $HOST_ID add binding port router $PROVIDER_ROUTER_ID port $PROVIDER_PORT_ID interface veth1)
if [ ! ${#BINDING} -gt 1 ]; then
    echo "FAILED to create host binding"
    exit 1
fi
echo "Added binding ${BINDING}"
