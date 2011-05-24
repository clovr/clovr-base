#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T" | sed -e 's/:/_/g'`

# Tag data that will be used in this pipeline
vp-add-dataset -o --tag-name=clovr_mapping_bowtie_noindices_reference /opt/hudson/NC_008253.fna
vp-add-dataset -o --tag-name=clovr_mapping_bowtie_noindices_input_reads /opt/hudson/e_coli_1000.fq

# Generate configuration file that will be used by the pipeline
vp-describe-protocols --config-from-protocol=clovr_mapping_bowtie_noindices \
    -c input.REFERENCE_TAG=clovr_mapping_bowtie_noindices_reference \
    -c input.INPUT_READS_TAG=clovr_mapping_bowtie_noindices_input_reads \
    -c pipeline.PIPELINE_NAME=clovr_mapping_bowtie_noindices_${DATE} \
    -c params.BOWTIE_BUILD_OPTS="-t 8" \
    -c params.OUTPUT_PREFIX="e_coli" > /tmp/$$.pipeline.conf

# Run pipeline, block on checking status and verify exit code indicates a successful run
TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-config=/tmp/$$.pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME
