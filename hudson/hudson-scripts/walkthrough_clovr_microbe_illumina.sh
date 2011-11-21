#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T" | sed -e 's/:/_/g'`

vp-add-dataset -o --tag-name=clovr_microbe_illumina_walkthrough_tag_$2 /opt/hudson/walkthrough_datasets/clovr_microbe_illumina/ecoli/illumina_4M_1.fastq /opt/hudson/walkthrough_datasets/clovr_microbe_illumina/ecoli/illumina_4M_2.fastq 

vp-describe-protocols --config-from-protocol=clovr_microbe_illumina \
    -c input.SHORT_PAIRED_TAG=clovr_microbe_illumina_walkthrough_tag_$2 \
    -c params.OUTPUT_PREFIX=test \
    -c params.ORGANISM="Eschirecia coli" \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    -c cluster.TERMINATE_ONFINISH=false \
    -c pipeline.PIPELINE_DESC="Hudson CloVR Micorbe Illumina walkthrough Test $2" \
    > /tmp/$$.pipeline.conf.${DATE}


TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-config /tmp/$$.pipeline.conf.${DATE} --overwrite`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?




