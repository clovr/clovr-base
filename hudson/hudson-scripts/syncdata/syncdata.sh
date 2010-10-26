#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

/opt/vappio-scripts/syncdata.sh --synchronous

HOSTNAME=`hostname -f`
du /mnt/staging > /tmp/stagingbefore.$$.out
/opt/vappio-scripts/seeding.sh $HOSTNAME exec.q
du /mnt/staging > /tmp/stagingafter.$$.out

cmp /tmp/stagingbefore.$$.out /tmp/stagingafter.$$.out

if [ $? -ne 0 ]; then 
    echo "error, change in disk usage"
fi

du /mnt/staging > /tmp/stagingbefore.$$.out
/opt/vappio-scripts/staging.sh $HOSTNAME 
du /mnt/staging > /tmp/stagingafter.$$.out

cmp /tmp/stagingbefore.$$.out /tmp/stagingafter.$$.out

if [ $? -ne 0 ]; then
    echo "error, change in disk usage"
    exit 1
fi



