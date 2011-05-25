#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

# Tag data that will be used in this pipeline
vp-add-dataset -o --tag-name=clovr_mapping_bowtie_indices_paired_reads_1 /opt/hudson/rna_seq_data/test1.txt /opt/hudson/rna_seq_data/test2.txt
vp-add-dataset -o --tag-name=clovr_mapping_bowtie_indices_paired_reads_2 /opt/hudson/rna_seq_data/testb1.txt /opt/hudson/rna_seq_data/testb2.txt
vp-add-dataset -o --tag-name=clovr_mapping_bowtie_indices_bowtie_index /opt/hudson/rna_seq_data/bowtie_indices/*

# Generate configuration file that will be used by the pipeline
vp-describe-protocols --config-from-protocol=clovr_mapping_bowtie_indices \
    -c input.INPUT_PAIRED_TAG="clovr_mapping_bowtie_indices_paired_reads_1,clovr_mapping_bowtie_indices_paired_reads_2" \
    -c input.REFERENCE_TAG=clovr_mapping_bowtie_indices_bowtie_index \
    -c params.MAX_INSERT_SIZE=300 \
    -c pipeline.PIPELINE_NAME=clovr_mapping_bowtie_indices_${DATE} \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
     > /tmp/$$.pipeline.conf

# Run pipeline, block on checking status and verify exit code indicates a successful run
TASK_NAME=`runPipeline.py --name local  --print-task-name --pipeline-name clovr_mapping_bowtie_indices_$$ --pipeline=clovr_wrapper --pipeline-config=/tmp/$$.pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME
