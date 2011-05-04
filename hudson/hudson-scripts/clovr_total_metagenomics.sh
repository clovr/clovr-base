#!/bin/bash
set -e 
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T" | sed -e 's/:/_/g'`

# Need to tag our data prior to kicking off the pipeline 
vp-add-dataset --tag-name=clovr_total_metagenomics_hudson /opt/hudson/MOMSP_454Reads_Region1_subset2.fasta -o

vp-describe-protocols --config-from-protocol=clovr_total_metagenomics \
    -c input.INPUT_TAG=clovr_total_metagenomics_hudson \
    -c pipeline.PIPELINE_NAME=${DATE} \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    > /tmp/$$.pipeline.conf.${DATE}


TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-name microbe_$$_${DATE} --pipeline clovr_wrapper --pipeline-config /tmp/$$.pipeline.conf.${DATE}`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?
