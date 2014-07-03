#!/bin/bash

# This is a script for running neutron thirdparty test in jenkins
# This does the folloing:
#   - Read the configuration for thirdparty testing
#   - Run midonet_stack.sh
#   - Publish logs to the log server
#   - Vote and post comment on gerrit

set -x
set -a

MIDOSTACK_TOPDIR=$(cd $(dirname $0)/../../../ && pwd)
CI_SCRIPT_DIR=$(cd $(dirname $0) && pwd)

MIDOSTACK_LOG_DIR=${MIDOSTACK_LOG_DIR:-/tmp/midostack_log}
PUBLIC_LOG_DIR=$MIDOSTACK_LOG_DIR/devstack
PRIVATE_LOG_DIR=$MIDOSTACK_LOG_DIR/midonet
rm -rf $MIDOSTACK_LOG_DIR && mkdir -p $MIDOSTACK_LOG_DIR
rm -rf $PUBLIC_LOG_DIR && mkdir -p $PUBLIC_LOG_DIR
rm -rf $PRIVATE_LOG_DIR && mkdir -p $PRIVATE_LOG_DIR

MIDOSTACK_CONFIG=$CI_SCRIPT_DIR/midostack.conf

# Read the config file
[ -f $MIDOSTACK_CONFIG ] && {
    . $MIDOSTACK_CONFIG
} || {
    echo Aborting: $MIDOSTACK_CONFIG is missing.
    exit 1
}


# private log files
MIDOSTACK_MIDONET_STACK_LOGFILE=$PRIVATE_LOG_DIR/midonet_stack.console.log

# public log files
TEMPEST_CONSOLE_LOGFILE=$PUBLIC_LOG_DIR/tempest_console.log

# Run midostack
$MIDOSTACK_TOPDIR/midonet_stack.sh | tee $MIDOSTACK_MIDONET_STACK_LOGFILE

RESULT=${PIPESTATUS[0]}
#TODO(tomoe) exit when errord out

# Run tempest now
$CI_SCRIPT_DIR/run_tempest.sh 2>&1 | tee $TEMPEST_CONSOLE_LOGFILE
TEMPEST_EXIT_CODE=${PIPESTATUS[0]}

echo === Tempest test result: $TEMPEST_EXIT_CODE

if [ $TEMPEST_EXIT_CODE -eq 0 ] ; then
    VOTE=+1
    VERDICT="SUCCESS"
else
    VOTE=0
    VERDICT="FAILURE"
fi


function prepare_public_logs(){
    echo "Midokura CI Bot contact:  mido-openstack-dev@midokura.com" > $PUBLIC_LOG_DIR/CONTACT.txt
}

function prepare_private_logs(){
    cp  -r /var/log/midolman/ $PRIVATE_LOG_DIR/
    sudo cp -r /var/log/tomcat7/ $PRIVATE_LOG_DIR/
    sudo chmod 777 $PRIVATE_LOG_DIR/tomcat7
}

prepare_public_logs
prepare_private_logs

TIMESTAMP=$(date +'%Y-%m-%d-%H%M%S')
PUBLIC_LOG_PATH=${PUBLIC_LOG_PATH:-ci_midokura_logs_$TIMESTAMP}

[ $MIDOSTACK_THIRDPARTY_PUBLISH_LOGS = "True" ] && {

    # publish public logs
    scp -r $PUBLIC_LOG_DIR/ midokura@3rdparty-logs.midokura.com:/var/www/results/$PUBLIC_LOG_PATH

    # save private logs
    scp -r $PRIVATE_LOG_DIR/ midokura@3rdparty-logs.midokura.com:/var/www/midokura/$PUBLIC_LOG_PATH
}

[ $MIDOSTACK_THIRDPARTY_VOTE_ENABLED = "True" ] && {
    # Vote +1 for success, 0 (not -1) for failure and comment on Gerrit
    ssh -p 29418 midokura@review.openstack.org gerrit review --verified=$VOTE $GERRIT_PATCHSET_REVISION -m \"$VERDICT http://3rdparty-logs.midokura.com/$PUBLIC_LOG_PATH\"
}

exit $TEMPEST_EXIT_CODE
