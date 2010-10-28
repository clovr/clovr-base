#!/bin/bash
set -e
source /root/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

touch /tmp/clovr_sleep_1 /tmp/clovr_sleep_2 /tmp/clovr_sleep_3

vp-add-dataset -o --tag-name=clovr_sleep_files /tmp/clovr_sleep_*

vp-describe-protocols --config-from-protocol=clovr_sleep \
    -c input.INPUT_TAG=clovr_sleep_files \
    -c input.PIPELINE_NAME=clovr_sleep_${DATE} \
    > /tmp/pipeline.conf

TASK_NAME=`runPipeline.py --print-task-name --pipeline clovr_wrapper --name local -n clovr_sleep_$$ --pipeline-config=/tmp/pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

taskStatus.py --name local --exit-code --block $TASK_NAME

exit $?
