#!/bin/bash -xe

# Start Zookeeper


if [ `get_ubuntu_codename` = "trusty" ]; then
    sudo apt-get install -y zookeeper zookeeperd
else
    sudo apt-get install -y zookeeper
fi

stop_service zookeeper
start_service zookeeper
if [ $? -gt 0 ]
then
    echo "Exiting. Zookeeper service failed to start. Check that it has been installed correctly (dpkg -l | grep zookeeper)."
    echo "Otherwise, check if there may be a zombie zookeeper process running (use ps -ef | grep zookeeper)."
    exit 1
fi
