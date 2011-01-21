#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

# Tag data that will be used in this pipeline
vp-add-dataset -o --tag-name=clovr_align_bowtie_reference /opt/hudson/NC_008253.fna
vp-add-dataset -o --tag-name=clovr_align_bowtie_input_reads /opt/hudson/e_coli_1000.fq

# Generate configuration file that will be used by the pipeline
vp-describe-protocols --config-from-protocol=clovr_align_bowtie \
    -c input.REFERENCE_TAG=clovr_align_bowtie_reference \
    -c input.INPUT_READS_TAG=clovr_align_bowtie_input_reads \
    -c pipeline.PIPELINE_NAME=clovr_align_bowtie_${DATE} \
    -c params.BOWTIE_BUILD_OPTS="-t 8" \
    -c params.OUTPUT_PREFIX="e_coli" \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    > /tmp/$$.pipeline.conf.${DATE}


# Run pipeline, block on checking status and verify exit code indicates a successful run
TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-name clovr_align_bowtie_$$_${DATE} --pipeline clovr_wrapper --pipeline-config /tmp/$$.pipeline.conf.${DATE}`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME
