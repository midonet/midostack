#!/bin/bash -xe


if [ "$BUILD_SOURCES" = "true" ]; then

    MIDONET_SRC_DIR=$MIDO_DEST/midonet

    # Create the dest dir in case it doesn't exist
    # Github clone will fail to run otherwise
    if [ ! -d $MIDO_DEST ]; then
        echo "Creating midonet destination directory... $MIDO_DEST"
        sudo mkdir -p $MIDO_DEST
        sudo chmod -R 777 $DEST
    fi

    # Get MidoNet source and install
    if [ ! -d "$MIDONET_SRC_DIR" ]; then
        git_clone $MIDONET_GIT_REPO $MIDONET_SRC_DIR $MIDONET_GIT_BRANCH
        if [ $? -gt 0 ]
        then
            echo $?
            echo "Exiting. Cloning MidoNet git repo $MIDONET_GIT_REPO (branch $MIDONET_GIT_BRANCH) failed, please check if environment variable MIDONET_GIT_REPO and MIDONET_GIT_BRANCH."
            exit 1
        fi
    fi
    cd $MIDONET_SRC_DIR && git submodule update --init

    # Build midolman
    if $MIDO_MVN_CLEAN ; then
        cd $MIDONET_SRC_DIR && mvn clean install -DskipTests -PfatJar
    else
        cd $MIDONET_SRC_DIR && mvn install -DskipTests -PfatJar
    fi
    if [ $? -gt 0 ]
    then
        echo "Exiting. MidoNet Maven install failed."
        exit 1
    fi

    # Change MIDO_HOME (used by mm-ctl / mm-dpctl) to point at deps dir
    MIDO_HOME=$MIDONET_SRC_DIR/midodeps
    MIDO_BOOTSTRAP_JAR=$MIDO_HOME/midonet-jdk-bootstrap.jar
    MIDO_JAR=$MIDO_HOME/midolman.jar

    MIDOLMAN_BUNDLE_VERSION=`mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep -v INFO | grep -v WARNING`
    MIDOLMAN_TGT_DIR="$MIDONET_SRC_DIR/midolman/target"
    MIDOLMAN_JAR_FILE="$MIDOLMAN_TGT_DIR/midolman-$MIDOLMAN_BUNDLE_VERSION-jar-with-dependencies.jar"
    echo "midolman-jar-file is $MIDOLMAN_JAR_FILE"

    mvn install:install-file -Dfile="$MIDOLMAN_JAR_FILE" \
                             -DgroupId=org.midonet \
                             -DartifactId=midolman-with-dependencies \
                             -Dversion=$MIDOLMAN_BUNDLE_VERSION \
                             -Dpackaging=jar
    if [ $? -gt 0 ]
    then
        echo "Exiting. MidoNet Maven install failed."
        exit 1
    fi

    MIDO_BOOTSTRAP_TGT_DIR="$MIDONET_SRC_DIR/midonet-jdk-bootstrap/target"
    MIDO_BOOTSTRAP_JAR_FILE="$MIDO_BOOTSTRAP_TGT_DIR/midonet-jdk-bootstrap-$MIDOLMAN_BUNDLE_VERSION.jar"
    echo "midonet-jdk-bootstrap-jar-file is $MIDO_BOOTSTRAP_JAR_FILE"

    # Jars have been created in earlier build step, put them all in one deps dir
    mkdir -p $MIDO_HOME
    cp $MIDOLMAN_JAR_FILE $MIDO_JAR
    cp $MIDO_BOOTSTRAP_JAR_FILE $MIDO_BOOTSTRAP_JAR
    cp -r $MIDOLMAN_TGT_DIR/dep $MIDO_HOME/

    # Place our executables in /usr/local/bin
    LOCAL_BIN_DIR=/usr/local/bin/
    sudo cp $MIDO_DIR/scripts/binproxy $LOCAL_BIN_DIR/mm-ctl
    sudo cp $MIDO_DIR/scripts/binproxy $LOCAL_BIN_DIR/mm-dpctl

    # Create the midolman dir in case it doesn't exist
    # Midolman will fail to run otherwise
    if [ ! -d $MIDOLMAN_CONF_DIR ]; then
        sudo mkdir -p $MIDOLMAN_CONF_DIR
    fi
    # These config files are needed - create if not present
    if [ ! -f $MIDOLMAN_CONF_DIR/logback-dpctl.xml ]; then
        sudo cp $MIDONET_SRC_DIR/midolman/conf/logback-dpctl.xml $MIDOLMAN_CONF_DIR/
    fi
    if [ ! -f $MIDOLMAN_CONF_DIR/midolman.conf ]; then
        sudo cp $MIDONET_SRC_DIR/midolman/conf/midolman.conf $MIDOLMAN_CONF_DIR/
    fi

    export PATH=$PATH:$MIDONET_CLIENT_DIR/src:$MIDONET_CLIENT_DIR/src/bin

fi
