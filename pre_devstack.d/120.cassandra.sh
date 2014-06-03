#!/bin/bash -xe

# Configure and start Cassandra

if [[ "$os_VENDOR" =~ (Red Hat) || "$os_VENDOR" =~ (CentOS) ]]; then
    CASSANDRA_FILE='/etc/cassandra/conf/cassandra.yaml'
    CASSANDRA_ENV_FILE='/etc/cassandra/conf/cassandra-env.sh'

    sudo chkconfig cassandra on

elif [[ "$os_VENDOR" =~ (Ubuntu) || "$os_VENDOR" =~ (Debian) ]]; then
    CASSANDRA_FILE='/etc/cassandra/cassandra.yaml'
    CASSANDRA_ENV_FILE='/etc/cassandra/cassandra-env.sh'

    sudo service cassandra stop
    sudo chown cassandra:cassandra /var/lib/cassandra
    sudo rm -rf /var/lib/cassandra/data/system/LocationInfo
fi

# Modify configurations
sudo sed -i -e "s/^cluster_name:.*$/cluster_name: \'midonet\'/g" $CASSANDRA_FILE
sudo sed -i 's/\(MAX_HEAP_SIZE=\).*$/\1128M/' $CASSANDRA_ENV_FILE
sudo sed -i 's/\(HEAP_NEWSIZE=\).*$/\164M/' $CASSANDRA_ENV_FILE
# Cassandra seems to need at least 228k stack working with Java 7.
# Related bug: https://issues.apache.org/jira/browse/CASSANDRA-5895
sudo sed -i -e "s/-Xss180k/-Xss228k/g" $CASSANDRA_ENV_FILE


# Restart Cassandra
stop_service cassandra
sudo sed -i -e "s/127.0.0.1 localhost/127.0.0.1 localhost $(hostname)/g" /etc/hosts
start_service cassandra
if [ $? -gt 0 ]
then
    echo "Exiting. Cassandra service failed to start. Check that it has been installed correctly (dpkg -l | grep cassandra)."
    echo "Otherwise, check if there may be a zombie Cassandra process running (use ps -ef | grep cassandra)."
    exit 1
fi
