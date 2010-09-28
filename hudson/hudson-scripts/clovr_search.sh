#!/bin/bash
set -e
source /root/clovrEnv.sh

vp-add-dataset -o --tag-name=NC_000964_peps /opt/hudson/NC_000964/NC_000964.faa

vp-add-dataset -o --tag-name=NC_000964_blastpdb /opt/hudson/NC_000964/NC_000964.faa*


DATE=`date +"%m-%d-%Y-%T"`

vp-describe-protocols --config-from-protocol=clovr_search -c input.INPUT_TAG=NC_000964_peps -c input.REF_DB_TAG=NC_000964_blastpdb -c input.PIPELINE_NAME=${DATE} -c misc.PROGRAM=blastp > /tmp/pipeline.conf

TASK_NAME=`runPipeline.py --print-task-name --pipeline clovr_wrapper --name local -n blastall$$ -- --CONFIG_FILE=/tmp/pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

taskStatus.py --name local --exit-code --block $TASK_NAME

exit $?
