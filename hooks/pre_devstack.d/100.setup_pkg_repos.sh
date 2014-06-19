#!/bin/bash -x

if [[ "$os_VENDOR" =~ (Red Hat) || "$os_VENDOR" =~ (CentOS) ]]; then
    ## RHEL Stuff ##
    # Sources not supported
    if [ $BUILD_SOURCES = true ]; then
        echo "Build sources not supported with Red Hat and CentOS distros currently";
        exit 1;
    fi

    # midokura repo
    sudo cp $MIDO_DIR/config_files/midokura.repo /etc/yum.repos.d/

    # datastax repo
    sudo cp $MIDO_DIR/config_files/datastax.repo /etc/yum.repos.d/

elif [[ "$os_VENDOR" =~ (Ubuntu) || "$os_VENDOR" =~ (Debian) ]]; then
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


    # Add Midokura Repository
    MIDONET_SRC="deb [trusted=1 arch=amd64] http://$MIDO_APT_USER:$MIDO_APT_PASSWORD@apt.midokura.com/midonet/$PKG_MAJOR_VERSION/$PKG_STATUS_VERSION $PKG_OS_RELEASE main non-free test"
    MIDONET_LIST_FILE=/etc/apt/sources.list.d/midonet.list
    if [ ! -f $MIDONET_LIST_FILE ]; then
        echo "Adding sources from Midonet package daily"
        echo -e $MIDONET_SRC | sudo tee $MIDONET_LIST_FILE
    fi
    # Download and install Midokura public key to validate software authenticity
    curl -k http://$MIDO_APT_USER:$MIDO_APT_PASSWORD@apt.midokura.com/packages.midokura.key | sudo apt-key add -

    sudo apt-get -y update
fi
