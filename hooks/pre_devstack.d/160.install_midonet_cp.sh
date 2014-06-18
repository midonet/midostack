#!/bin/bash -xe

# Currently source only since MidoNet CP
# doesn't provide package at this moment.
if [ $BUILD_SOURCES = true ]; then


    # Install control panel
    sudo apt-get install -y ruby1.9.1 make g++
    sudo gem install compass

    # Build node.js
    if [ -z `which node` ]; then
        git clone https://github.com/joyent/node.git -b v.0.11.12
        git_clone $NODEJS_REPO $NODEJS_DEST $NODEJS_BRANCH
        cd $NODEJS_DEST
        ./configure && make
        sudo make install
    fi


    sudo npm install -g grunt-cli
    sudo npm install -g bower
    sudo rm -rf $HOME/tmp

    git_clone $MIDONET_CP_REPO $MIDONET_CP_DEST $MIDONET_CP_BRANCH
    cd $MIDONET_CP_DEST
    npm install
    sed -i "/window.EmberENV.rootURL/c\window.EmberENV.rootURL = 'http://$HOST_IP:$MIDONET_CP_PORT';" ./config/user.js
    sed -i "/window.EmberENV.api_host/c\window.EmberENV.api_host = 'http://$HOST_IP:$MIDONET_API_PORT';" ./config/user.js
    sed -i "/window.EmberENV.openstack_host/c\window.EmberENV.openstack_host = 'http://$HOST_IP';" ./config/environment.js
    sed -i "/window.EmberENV.API_TOKEN/c\window.EmberENV.API_TOKEN = '$ADMIN_PASSWORD';" ./config/environment.js

fi
