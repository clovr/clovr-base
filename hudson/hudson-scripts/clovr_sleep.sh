#!/bin/bash
set -e
source /root/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

touch /tmp/clovr_sleep_1 /tmp/clovr_sleep_2 /tmp/clovr_sleep_3

vp-add-dataset -o --tag-name=clovr_sleep_files /tmp/clovr_sleep_*

vp-describe-protocols --config-from-protocol=clovr_sleep \
    -c input.INPUT_TAG=clovr_sleep_files \
    -c input.PIPELINE_NAME=clovr_sleep_${DATE} \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    > /tmp/$$.pipeline.conf.${DATE}

TASK_NAME=`vp-run-pipeline --print-task-name --pipeline clovr_wrapper --pipeline-name clovr_sleep_$$_${DATE} --pipeline-config /tmp/$$.pipeline.conf.${DATE}`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?
