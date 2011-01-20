#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

# Tag data that will be used in this pipeline
vp-add-dataset -o --tag-name=clovr_mapping_bowtie_indices_reference /opt/hudson/bowtie_index/NC_008253*
vp-add-dataset -o --tag-name=clovr_mapping_bowtie_indices_input_reads /opt/hudson/e_coli_1000.fq

# Generate configuration file that will be used by the pipeline
vp-describe-protocols --config-from-protocol=clovr_mapping_bowtie_indices \
    -c input.REFERENCE_TAG=clovr_mapping_bowtie_indices_reference \
    -c input.INPUT_READS_TAG=clovr_mapping_bowtie_indices_input_reads \
    -c pipeline.PIPELINE_NAME=clovr_mapping_bowtie_indices_${DATE} \
     > /tmp/$$.pipeline.conf

# Run pipeline, block on checking status and verify exit code indicates a successful run
TASK_NAME=`runPipeline.py --name local  --print-task-name --pipeline-name clovr_mapping_bowtie_indices_$$ --pipeline=clovr_wrapper --pipeline-config=/tmp/$$.pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME
