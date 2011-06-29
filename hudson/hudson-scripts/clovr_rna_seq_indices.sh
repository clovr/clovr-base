#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

# Tag data that will be used in this pipeline
vp-add-dataset -o --tag-name=clovr_mapping_bowtie_indices_paired_reads_1 /opt/hudson/rna_seq_data/test1.txt /opt/hudson/rna_seq_data/test2.txt
vp-add-dataset -o --tag-name=clovr_mapping_bowtie_indices_paired_reads_2 /opt/hudson/rna_seq_data/testb1.txt /opt/hudson/rna_seq_data/testb2.txt
vp-add-dataset -o --tag-name=clovr_mapping_bowtie_indices_bowtie_index /opt/hudson/rna_seq_data/bowtie_indices/*
vp-add-dataset -o --tag-name=clovr_mapping_bowtie_noindices_ref /opt/hudson/rna_seq_data/gasalab49.fsa
vp-add-dataset -o --tag-name=clovr_rna_seq_prok_expression_analysis_gff3 /opt/hudson/rna_seq_data/gasalab49.gff3
vp-add-dataset -o --tag-name=clovr_rna_seq_prok_expression_analysis_sample_mapping /opt/hudson/rna_seq_data/sample_matching.txt

vp-describe-protocols --config-from-protocol=clovr_rna_seq_indices \
    -c input.REFERENCE_BOWTIE_TAG=clovr_mapping_bowtie_indices_bowtie_index \
    -c input.REFERENCE_FASTA_TAG=clovr_mapping_bowtie_noindices_ref \
    -c input.INPUT_PAIRED_TAG="clovr_mapping_bowtie_indices_paired_reads_1,clovr_mapping_bowtie_indices_paired_reads_2" \
    -c input.INPUT_GFF3_TAG=clovr_rna_seq_prok_expression_analysis_gff3 \
    -c input.INPUT_SAMPLE_MAP_TAG=clovr_rna_seq_prok_expression_analysis_sample_mapping \
    -c params.COUNT_MODE="union" \
    -c params.COUNTING_FEATURE="CDS" \
    -c params.MIN_ALIGN_QUAL=0 \
    -c params.IS_STRANDED="no" \
    -c params.ID_ATTRIBUTE="ID" \
    -c pipeline.PIPELINE_DESC="Hudson CloVR RNA Seq Indices" \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 > /tmp/$$.pipeline.conf

# Run pipeline, block on checking status and verify exit code indicates a successful run
TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-config=/tmp/$$.pipeline.conf --overwrite`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME
