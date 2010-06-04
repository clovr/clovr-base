#! /bin/bash

source /opt/vappio-scripts/clovrEnv.sh

/opt/vappio-scripts/syncdata.sh
/opt/vappio-scripts/syncdata.sh --synchronous

HOSTNAME=`hostname -f`
du /mnt/staging > stagingbefore.out
sudo /opt/vappio-scripts/seeding.sh $HOSTNAME exec.q
du /mnt/staging > stagingafter.out

cmp stagingbefore.out stagingafter.out

if [ $? -ne 0 ]; then 
    echo "error, change in disk usage"
fi

du /mnt/staging > stagingbefore.out
sudo /opt/vappio-scripts/staging.sh $HOSTNAME exec.q
du /mnt/staging > stagingafter.out

cmp stagingbefore.out stagingafter.out

if [ $? -ne 0 ]; then
    echo "error, change in disk usage"
fi



