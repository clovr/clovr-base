#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

vp-add-dataset -o --tag-name=clovr_microbe_illumina_tag /opt/hudson/illumina_data/partial_reads_1.fastq /opt/hudson/illumina_data/partial_reads_2.fastq 

vp-describe-protocols --config-from-protocol=clovr_microbe_illumina \
    -c input.SHORT_PAIRED_TAG=clovr_microbe_illumina_tag \
    -c input.PIPELINE_NAME=clovr_microbe_illumina-${DATE} \
    -c input.OUTPUT_PREFIX=test \
    -c input.ORGANISM="Genus species" \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    > /tmp/$$.pipeline.conf.${DATE}


TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-name microbe_illumina_$$_${DATE} --pipeline clovr_wrapper --pipeline-config /tmp/$$.pipeline.conf.${DATE}`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?




