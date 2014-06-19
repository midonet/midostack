#!/bin/bash -xe

# Configure midonet-cli
ADMIN_TENANT_ID=$(keystone tenant-list | grep -w admin | awk '{ print $2 }')
MIDONETRC=~/.midonetrc
touch $MIDONETRC
iniset $MIDONETRC cli username "admin"
iniset $MIDONETRC cli password "$ADMIN_PASSWORD"
iniset $MIDONETRC cli project_id "admin"
iniset $MIDONETRC cli api_url "$MIDONET_API_URI"
iniset $MIDONETRC cli tenant "$ADMIN_TENANT_ID"
