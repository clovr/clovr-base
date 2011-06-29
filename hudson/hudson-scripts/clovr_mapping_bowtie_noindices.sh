#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

# Tag data that will be used in this pipeline
vp-add-dataset -o --tag-name=clovr_mapping_bowtie_indices_paired_reads_1 /opt/hudson/rna_seq_data/test1.txt /opt/hudson/rna_seq_data/test2.txt
vp-add-dataset -o --tag-name=clovr_mapping_bowtie_indices_paired_reads_2 /opt/hudson/rna_seq_data/testb1.txt /opt/hudson/rna_seq_data/testb2.txt
vp-add-dataset -o --tag-name=clovr_mapping_bowtie_noindices_ref /opt/hudson/rna_seq_data/gasalab49.fsa

# Generate configuration file that will be used by the pipeline
vp-describe-protocols --config-from-protocol=clovr_mapping_bowtie_noindices \
    -c input.REFERENCE_TAG=clovr_mapping_bowtie_noindices_ref \
    -c input.INPUT_PAIRED_TAG="clovr_mapping_bowtie_indices_paired_reads_1,clovr_mapping_bowtie_indices_paired_reads_2" \
    -c cluster.CLUSTER_NAME=$1 \
    -c pipeline.PIPELINE_DESC="Hudson CloVR Mapping Bowtie Noindices Test" \
    -c cluster.CLUSTER_CREDENTIAL=$2 > /tmp/$$.pipeline.conf

# Run pipeline, block on checking status and verify exit code indicates a successful run
TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-config=/tmp/$$.pipeline.conf --overwrite`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME
