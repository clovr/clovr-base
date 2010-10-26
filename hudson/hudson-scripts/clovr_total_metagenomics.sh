#!/bin/bash
set -e 
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

# Need to tag our data prior to kicking off the pipeline 
vp-add-dataset --tag-name=clovr_total_metagenomics_hudson /opt/hudson/MOMSP_454Reads_Region1_subset2.fasta -o

vp-describe-protocols --config-from-protocol=clovr_total_metagenomics -c input.INPUT_TAG=clovr_total_metagenomics_hudson -c input.PIPELINE_NAME=${DATE} > /tmp/$$.pipeline.conf

TASK_NAME=`runPipeline.py --name local  --print-task-name --pipeline-name microbe-$DATE --pipeline=clovr_wrapper -- --CONFIG_FILE=/tmp/$$.pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?
