#!/bin/bash -xe

# Start MidoNet services

MIDONET_API_PORT=${MIDONET_API_PORT:-8081}
MIDONET_API_URI=${MIDONET_API_URI:-http://$HOST_IP:$MIDONET_API_PORT/midonet-api}

if [[ "$os_VENDOR" =~ (Red Hat) || "$os_VENDOR" =~ (CentOS) ]]; then
    TOMCAT=tomcat6
else
    TOMCAT=tomcat7
fi
stop_service $TOMCAT


if [ $BUILD_SOURCES = true ]; then

    MIDO_SCREEN_EXISTS=$(screen -ls | egrep "[0-9].$MIDONET_SCREEN_NAME")
    if [[ $MIDO_SCREEN_EXISTS == '' ]]; then
        USE_MIDO_SCREEN=$(trueorfalse True $USE_MIDO_SCREEN)
        if [[ "$USE_MIDO_SCREEN" == "True" ]]; then
            # Create a new named screen to run processes in
            screen -d -m -S $MIDONET_SCREEN_NAME -t shell -s /bin/bash
            sleep 1

            # Set a reasonable status bar
            if [ -z "$MIDO_SCREEN_HARDSTATUS" ]; then
                MIDO_SCREEN_HARDSTATUS='%{= .} %-Lw%{= .}%> %n%f %t*%{= .}%+Lw%< %-=%{g}(%{d}%H/%l%{g})'
            fi
            screen -r $MIDONET_SCREEN_NAME -X hardstatus alwayslastline "$MIDO_SCREEN_HARDSTATUS"
            screen -r $MIDONET_SCREEN_NAME -X setenv PROMPT_COMMAND /bin/true
        fi

        # Clear screen rc file
        MIDO_SCREENRC=$MIDO_TOP_DIR/../$MIDONET_SCREEN_NAME-screenrc
        if [[ -e $MIDO_SCREENRC ]]; then
            rm -f $MIDO_SCREENRC
        fi
    else
        echo "You are already running a mido session."
        echo "To rejoin this session type 'screen -x mido'."
        echo "To destroy this session, type './midonet_unstack.sh'."
        exit 1
    fi

    enable_service midolman midonet-api midonet-cp

    # Midolman service must be stopped
    echo "Starting midolman"

    SCREEN_NAME=$MIDONET_SCREEN_NAME
    TOP_DIR=$MIDO_DIR

    screen_it midolman "cd $MIDONET_SRC_DIR && MAVEN_OPTS=\"$MAVEN_OPTS_MIDOLMAN\" mvn -pl midolman exec:exec"
    # Run the API with jetty:plugin
    # Tomcat need to be stopped
    echo "Starting midonet-api"
# put logback.xml to the classpath with "debug" level so mvn jetty:run can pick up
    sed -e 's/info/debug/' \
        -e 's,</configuration>,\
<logger name="org.apache.zookeeper" level="INFO" />\
<logger name="org.apache.cassandra" level="INFO" />\
<logger name="me.prettyprint.cassandra" level="INFO" />\
</configuration>,' \
       $MIDONET_SRC_DIR/midonet-api/conf/logback.xml.sample > \
       $MIDONET_SRC_DIR/midonet-api/target/classes/logback.xml

    screen_it midonet-api "cd $MIDONET_SRC_DIR && MAVEN_OPTS=\"$MAVEN_OPTS_API\" mvn -pl midonet-api jetty:run -Djetty.port=$MIDONET_API_PORT"
    screen_it midonet-cp "cd $MIDONET_CP_DEST && PORT=$MIDONET_CP_PORT grunt server"
    echo "* Making sure MidoNet API server is up and ready."

else # Use packages

    sudo sed -i -e "s/8080/$MIDONET_API_PORT/g" /etc/$TOMCAT/server.xml

    # Set up Tomcat configuration for midonet-api
    cat <<EOF | sudo tee /etc/$TOMCAT/Catalina/localhost/midonet-api.xml
    <Context path="/midonet-api"
            docBase="/usr/share/midonet-api"
                            antiResourceLocking="false" privileged="true" />
EOF

    start_service $TOMCAT
    start_service midolman
fi

STARTUPTIME=0
CONNECTED=1

while [ $CONNECTED -ne 0 ]
  do
    curl -fs $MIDONET_API_URI > /dev/null
    let CONNECTED=$?
    echo "Waiting for API server to start, may take some time. Have waited $STARTUPTIME seconds so far."
    sleep 2
    let STARTUPTIME=STARTUPTIME+2
done

echo "* API server is up, took $STARTUPTIME seconds"
unset ENABLED_SERVICES
unset SCREENRC
