#!/usr/bin/env bash

MIDO_DIR=$(pwd)
DEVSTACK_DIR="$MIDO_DIR/devstack"

source $MIDO_DIR/functions

# Check if devstack repo exists
is_devstack_cloned

# Midonet password. Used to simplify the passwords in the configurated localrc
MIDOSTACK_PASSWORD=${MIDOSTACK_PASSWORD:-gogomid0}

# Setting this value as 'false' will deploy a devstack with quantum and openvsitch
USE_MIDONET=${USE_MIDONET:-true}

# Destination directory
DEST=${DEST:-/opt/stack}

# First configuration file is our own 'localrc'
if [ -f $MIDO_DIR/localrc ]; then
    source $MIDO_DIR/localrc
fi


if [ $USE_MIDONET = true ]; then
    # Then load the midonetrc
    source $MIDO_DIR/midonetrc

    # Check access to github.com
    ssh -T -o StrictHostKeyChecking=no git@github.com
    [ $? == 255 ] && {
        echo "Exiting. Can't authenticate with Github via ssh; please check that your ssh key is present in ~/.ssh."
        exit 1
    }


    # apt package pinning (zookeeper 3.4.5, ovs-dp 1.10)
    UBUNTU_ARCHIVE="http://us.archive.ubuntu.com/ubuntu/"
    RARING_SRC="deb $UBUNTU_ARCHIVE raring universe\ndeb-src $UBUNTU_ARCHIVE raring universe"
    RARING_LIST_FILE=/etc/apt/sources.list.d/raring.list
    if [ ! -f $RARING_LIST_FILE ]; then
        echo "Adding sources from Ubuntu Raring release"
        echo -e $RARING_SRC | sudo tee $RARING_LIST_FILE
    fi

    SAUCY_SRC="deb $UBUNTU_ARCHIVE saucy universe\ndeb-src $UBUNTU_ARCHIVE saucy universe"
    SAUCY_LIST_FILE=/etc/apt/sources.list.d/saucy.list
    if [ ! -f $SAUCY_LIST_FILE ]; then
        echo "Adding sources from Ubuntu Saucy release"
        echo -e $SAUCY_SRC | sudo tee $SAUCY_LIST_FILE
    fi

    CASSANDRA_LIST_FILE=/etc/apt/sources.list.d/cassandra.list
    if [ ! -f $CASSANDRA_LIST_FILE ]; then 
        echo "Adding Cassandra sources"
        echo -e 'deb http://www.apache.org/dist/cassandra/debian 11x main\ndeb-src http://www.apache.org/dist/cassandra/debian 11x main' | sudo tee $CASSANDRA_LIST_FILE
        sudo gpg --keyserver pgp.mit.edu --recv-keys F758CE318D77295D
        sudo gpg --export --armor F758CE318D77295D | sudo apt-key add -
        sudo gpg --keyserver pgp.mit.edu --recv-keys 2B5C1B00
        sudo gpg --export --armor 2B5C1B00 | sudo apt-key add -
    fi

    sudo cp $MIDO_DIR/config_files/01midokura_apt_config /etc/apt/apt.conf.d/
    sudo cp $MIDO_DIR/config_files/01midokura_apt_preferences /etc/apt/preferences.d/

    sudo apt-get -y update

    # Install dependences
    sudo apt-get install -y python-dev libxml2-dev libxslt-dev openjdk-7-jdk openjdk-7-jre zookeeper zookeeperd cassandra openvswitch-datapath-dkms linux-headers-`uname -r` maven

    # Stop service zookeeper temporaly
    sudo service zookeeper stop

    # Configure casandra
    sudo service cassandra stop
    sudo chown cassandra:cassandra /var/lib/cassandra
    sudo rm -rf /var/lib/cassandra/data/system/LocationInfo
    # Configure Cassandra and restart
    CASSANDRA_FILE='/etc/cassandra/cassandra.yaml'
    sudo sed -i -e "s/^cluster_name:.*$/cluster_name: \'midonet\'/g" $CASSANDRA_FILE
    CASSANDRA_ENV_FILE='/etc/cassandra/cassandra-env.sh'
    sudo sed -i 's/\(MAX_HEAP_SIZE=\).*$/\1128M/' $CASSANDRA_ENV_FILE
    sudo sed -i 's/\(HEAP_NEWSIZE=\).*$/\164M/' $CASSANDRA_ENV_FILE
    # Cassandra seems to need at least 228k stack working with Java 7.
    # Related bug: https://issues.apache.org/jira/browse/CASSANDRA-5895
    sudo sed -i -e "s/-Xss180k/-Xss228k/g" $CASSANDRA_ENV_FILE
    sudo service cassandra start

    # Maven installs Java 6; make sure we set Java 7 as primary
    # JDK so that MidoNet Maven build works
    sudo update-java-alternatives -s java-1.7.0-openjdk-amd64

    # Create the midolman dir in case it doesn't exist
    # Midolman will fail to run otherwise
    if [ ! -d $MIDOLMAN_CONF_DIR ]; then
        sudo mkdir -p $MIDOLMAN_CONF_DIR
    fi

    # Create the dest dir in case it doesn't exist
    # Github clone will fail to run otherwise
    if [ ! -d $MIDO_DEST ]; then
        sudo mkdir -p $MIDO_DEST
        sudo chown $STACK_USER $DEST
        sudo chown $STACK_USER $MIDO_DEST
    fi

    # Get MidoNet source and install
    git clone $MIDONET_GIT_REPO $MIDONET_SRC_DIR
    if [ $? -gt 0 ]
    then
        echo "Exiting. Cloning MidoNet git repo $MIDONET_GIT_REPO (branch $MIDONET_GIT_BRANCH) failed, please check if environment variable MIDONET_GIT_REPO and MIDONET_GIT_BRANCH."
        exit 1
    fi
    cd $MIDONET_SRC_DIR
    git checkout $MIDONET_GIT_BRANCH

fi

# Execute stack script
# cp $MIDO_DIR/devstackrc $DEVSTACK_DIR/localrc
# cd $DEVSTACK_DIR && source stack.sh
