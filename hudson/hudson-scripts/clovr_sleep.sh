#!/bin/bash

source /root/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

cp /opt/hudson/clovr_sleep.config /tmp/pipeline.conf

sed -i -e "s/\${DATE}/$DATE/" /tmp/pipeline.conf

TASK_NAME=`runPipeline.py --print-task-name --pipeline clovr_wrapper --name local -n clovrsleep -- --CONFIG_FILE=/tmp/pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

taskStatus.py --name local --exit-code --block $TASK_NAME

exit $?
