#!/bin/bash
set -e
source /root/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T" | sed -e 's/:/_/g'`

touch /tmp/clovr_sleep_1 /tmp/clovr_sleep_2 /tmp/clovr_sleep_3

vp-add-dataset -o --tag-name=clovr_sleep_files_$2 /tmp/clovr_sleep_*

vp-describe-protocols --config-from-protocol=clovr_sleep \
    -c input.INPUT_TAG=clovr_sleep_files_$2 \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    -c cluster.TERMINATE_ONFINISH=false \
    -c pipeline.PIPELINE_DESC="Hudson CloVR Sleep Test $2" \
    > /tmp/$$.pipeline.conf.${DATE}

TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-config /tmp/$$.pipeline.conf.${DATE} --overwrite`

if [ "$?" != "0" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?
