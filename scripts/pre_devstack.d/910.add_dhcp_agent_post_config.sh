

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
