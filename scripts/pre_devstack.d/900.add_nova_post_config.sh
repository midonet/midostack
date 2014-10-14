
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
