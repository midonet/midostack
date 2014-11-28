#!/bin/bash

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

# This is a script for running neutron thirdparty test in jenkins
# This does the folloing:
#   - Read the configuration for thirdparty testing
#   - Run midonet_stack.sh
#   - Publish logs to the log server

set -x
set -a

MIDOSTACK_TOPDIR=$(cd $(dirname $0)/../../../ && pwd)
CI_SCRIPT_DIR=$(cd $(dirname $0) && pwd)

MIDOSTACK_LOG_DIR=${MIDOSTACK_LOG_DIR:-/tmp/midostack_log}
PUBLIC_LOG_DIR=$MIDOSTACK_LOG_DIR/devstack/
SCREEN_LOGDIR=$PUBLIC_LOG_DIR/$ZUUL_CHANGE/$ZUUL_PATCHSET/$BUILD_NUMBER

rm -rf $MIDOSTACK_LOG_DIR && mkdir -p $MIDOSTACK_LOG_DIR
rm -rf $PUBLIC_LOG_DIR && mkdir -p $PUBLIC_LOG_DIR
rm -rf $SCREEN_LOGDIR && mkdir -p $SCREEN_LOGDIR

MIDOSTACK_CONFIG=$CI_SCRIPT_DIR/midostack.conf

# Read the config file
[ -f $MIDOSTACK_CONFIG ] && {
    . $MIDOSTACK_CONFIG
} || {
    echo Aborting: $MIDOSTACK_CONFIG is missing.
    exit 1
}

#construct neutron branch
ZUUL_SUB_CHANGE="${ZUUL_CHANGE#${ZUUL_CHANGE%??}}"
NEUTRON_BRANCH=refs/changes/$ZUUL_SUB_CHANGE/$ZUUL_CHANGE/$ZUUL_PATCHSET

# public log files
TEMPEST_CONSOLE_LOGFILE=$SCREEN_LOGDIR/tempest_console.log

function prepare_public_logs(){
    echo "Midokura CI Bot contact:  mido-openstack-dev@midokura.com" > $SCREEN_LOGDIR/CONTACT.txt
}
prepare_public_logs

# Run midostack
$MIDOSTACK_TOPDIR/midonet_stack.sh -q

RESULT=${PIPESTATUS[0]}
if [ $RESULT -ne 0 ] ; then
    echo "midonet_stack.sh failed. Exiting..."
    scp -r $PUBLIC_LOG_DIR/$ZUUL_CHANGE midokura@3rdparty-logs.midokura.com:/var/www/results/
    exit 1
fi

# Run tempest now
$CI_SCRIPT_DIR/run_tempest.sh 2>&1 | tee $TEMPEST_CONSOLE_LOGFILE
TEMPEST_EXIT_CODE=${PIPESTATUS[0]}

echo === Tempest test result: $TEMPEST_EXIT_CODE

[ $MIDOSTACK_THIRDPARTY_PUBLISH_LOGS = "True" ] && {

    # publish public logs
    scp -r $PUBLIC_LOG_DIR/$ZUUL_CHANGE midokura@3rdparty-logs.midokura.com:/var/www/results/
}

exit $TEMPEST_EXIT_CODE
