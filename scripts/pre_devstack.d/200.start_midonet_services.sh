#!/bin/bash -xe

# Copyright 2014 Midokura SARL
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Start MidoNet services

MIDONET_API_URI=${MIDONET_API_URI:-http://$HOST_IP:$MIDONET_API_PORT/midonet-api}

stop_service tomcat7

# work around screen function inconsistency between different branches
shopt -s expand_aliases
if [ "$MIDOSTACK_OPENSTACK_BRANCH" == "stable/icehouse" ] ; then
    alias run_in_screen=screen_service
elif [ "$MIDOSTACK_OPENSTACK_BRANCH" == "stable/juno" ] ; then
    alias run_in_screen=screen_service
else
    alias run_in_screen=screen_process
fi

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

    # We are over writing SCREEN_NAME, so lets save and restore
    TMP_SCREEN_NAME=$SCREEN_NAME
    SCREEN_NAME=$MIDONET_SCREEN_NAME
    TOP_DIR=$MIDO_DIR

    # put config to the classpath and set loglevel to DEBUG for Midolman
    sed -e 's/"INFO"/"DEBUG"/'  \
        $MIDONET_SRC_DIR/midolman/conf/midolman-akka.conf > \
        $MIDONET_SRC_DIR/midolman/build/classes/main/application.conf
    cp  $MIDONET_SRC_DIR/midolman/src/test/resources/logback-test.xml  \
        $MIDONET_SRC_DIR/midolman/build/classes/main/logback.xml

    run_in_screen midolman "cd $MIDONET_SRC_DIR && ./gradlew -a :midolman:runWithSudo "
    # Run the API with jetty:plugin
    # Tomcat need to be stopped
    echo "Starting midonet-api"

    # put logback.xml to the classpath with "debug" level
    LOGBACK_FILE=$MIDONET_SRC_DIR/midonet-api/conf/logback.xml.dev
    if [ -f $LOGBACK_FILE ]; then
        cp $LOGBACK_FILE \
            $MIDONET_SRC_DIR/midonet-api/build/classes/main/logback.xml
    else
        # The old way
        sed -e 's/info/debug/' \
            -e 's,</configuration>,\
<logger name="org.apache.zookeeper" level="INFO" />\
<logger name="org.apache.cassandra" level="INFO" />\
<logger name="me.prettyprint.cassandra" level="INFO" />\
</configuration>,' \
           $MIDONET_SRC_DIR/midonet-api/conf/logback.xml.sample > \
           $MIDONET_SRC_DIR/midonet-api/build/classes/main/logback.xml
    fi

    run_in_screen midonet-api "cd $MIDONET_SRC_DIR && ./gradlew :midonet-api:jettyRun -Pport=$MIDONET_API_PORT "
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
MIDOSTACK_MIDONET_API_STARTUPTIME_LIMIT=${MIDOSTACK_MIDONET_API_STARTUPTIME_LIMIT:-180} # in sec

while [ $CONNECTED -ne 0 ]
  do
    curl -fs $MIDONET_API_URI > /dev/null
    let CONNECTED=$?
    echo "Waiting for API server to start, may take some time. Have waited $STARTUPTIME seconds so far."
    sleep 2
    let STARTUPTIME=STARTUPTIME+2
    if [ $STARTUPTIME -gt $MIDOSTACK_MIDONET_API_STARTUPTIME_LIMIT ] ;then
        echo "API server didn't start in $MIDOSTACK_MIDONET_API_STARTUPTIME_LIMIT seconds"
        exit 1
    fi
done

echo "* API server is up, took $STARTUPTIME seconds"
unset ENABLED_SERVICES
unset SCREENRC
SCREEN_NAME=$TMP_SCREEN_NAME
