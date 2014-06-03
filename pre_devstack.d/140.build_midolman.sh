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

    # Check if we have zinc installed
    ZINC_DIR=$MIDO_DEST/zinc
    if [ ! -d $ZINC_DIR ]; then
        ZINC_FILE_NAME=${ZINC_URL##*/}
        ZINC_FILE=$MIDO_DEST/$ZINC_FILE_NAME
        if [ -f $ZINC_FILE ]; then
            rm -f $ZINC_FILE
        fi
        sudo wget -c $ZINC_URL -O $ZINC_FILE
        echo "Downloading zinc from $ZINC_URL to $ZINC_FILE"
        sudo tar -zxf $ZINC_FILE -C "$MIDO_DEST"
        ZINC_DIR_NAME=${ZINC_FILE_NAME%%.tgz}
        ZINC_TMP_DIR=$MIDO_DEST/$ZINC_DIR_NAME
        sudo mv $ZINC_TMP_DIR $ZINC_DIR
        sudo rm $ZINC_FILE
    fi

    # Start zinc, restart if running
    if is_running "zinc"
    then
        echo "Stopping zinc"
        $ZINC_DIR/bin/zinc -shutdown
    fi

    echo "Starting zinc"
    $ZINC_DIR/bin/zinc -start

    # Get MidoNet source and install
    if [ ! -d "$MIDONET_SRC_DIR" ]; then
        git_clone $MIDONET_GIT_REPO $MIDONET_SRC_DIR $MIDONET_GIT_BRANCH
        if [ $? -gt 0 ]
        then
            echo $?
            echo "Exiting. Cloning MidoNet git repo $MIDONET_GIT_REPO (branch $MIDONET_GIT_BRANCH) failed, please check if environment variable MIDONET_GIT_REPO and MIDONET_GIT_BRANCH."
            exit 1
        fi
        cd $MIDONET_SRC_DIR && git submodule update --init
    fi

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

    MIDOLMAN_TGT_DIR="$MIDONET_SRC_DIR/midolman/target"
    MIDOLMAN_JAR_FILE="$MIDOLMAN_TGT_DIR/midolman-$MIDOLMAN_BUNDLE_VERSION-jar-with-dependencies.jar"
    echo "midolman-jar-file is $MIDOLMAN_JAR_FILE"

# TODO(tomoe) Need to revisit. Comment out for upstream work as it's failing on v1.4 branch
# for some reason
#    mvn install:install-file -Dfile="$MIDOLMAN_JAR_FILE" \
#                             -DgroupId=org.midonet \
#                             -DartifactId=midolman-with-dependencies \
#                             -Dversion=$MIDOLMAN_BUNDLE_VERSION \
#                             -Dpackaging=jar
#    if [ $? -gt 0 ]
#    then
#        echo "Exiting. MidoNet Maven install failed."
#        exit 1
#    fi

    # Place our executables in /usr/local/bin
    LOCAL_BIN_DIR=/usr/local/bin/
    sudo cp $MIDO_DIR/scripts/binproxy $LOCAL_BIN_DIR/mm-ctl
    sudo cp $MIDO_DIR/scripts/binproxy $LOCAL_BIN_DIR/mm-dpctl

    # Jars have been created in earlier build step, put them all in one deps dir
    MIDONET_DEPS_DIR=$MIDONET_SRC_DIR/midodeps
    mkdir -p $MIDONET_DEPS_DIR
    cp $MIDOLMAN_TGT_DIR/midolman-*.jar $MIDONET_DEPS_DIR/midolman.jar
    cp $MIDONET_SRC_DIR/midonet-jdk-bootstrap/target/midonet-jdk-bootstrap-*.jar $MIDONET_DEPS_DIR/midonet-jdk-bootstrap.jar
    cp -r $MIDOLMAN_TGT_DIR/dep $MIDONET_DEPS_DIR/

    # Change MIDO_HOME (used by mm-ctl / mm-dpctl) to point at deps dir
    export MIDO_HOME=$MIDONET_DEPS_DIR

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
    export PYTHONPATH=$MIDONET_CLIENT_DIR/src:$MIDONET_CLIENT_DIR/src/bin

fi
