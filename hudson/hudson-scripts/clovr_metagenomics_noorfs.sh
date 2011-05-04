#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

vp-add-dataset -o --tag-name=clovr_metagenomics_noorfs_fasta /opt/hudson/Metagenomic_data/ts1.small.fasta  /opt/hudson/Metagenomic_data/ts20.small.fasta  /opt/hudson/Metagenomic_data/ts29.small.fasta  /opt/hudson/Metagenomic_data/ts4.small.fasta   /opt/hudson/Metagenomic_data/ts50.small.fasta  /opt/hudson/Metagenomic_data/ts7.small.fasta /opt/hudson/Metagenomic_data/ts19.small.fasta  /opt/hudson/Metagenomic_data/ts21.small.fasta  /opt/hudson/Metagenomic_data/ts3.small.fasta   /opt/hudson/Metagenomic_data/ts49.small.fasta  /opt/hudson/Metagenomic_data/ts51.small.fasta  /opt/hudson/Metagenomic_data/ts8.small.fasta /opt/hudson/Metagenomic_data/ts2.small.fasta   /opt/hudson/Metagenomic_data/ts28.small.fasta  /opt/hudson/Metagenomic_data/ts30.small.fasta  /opt/hudson/Metagenomic_data/ts5.small.fasta   /opt/hudson/Metagenomic_data/ts6.small.fasta   /opt/hudson/Metagenomic_data/ts9.small.fasta

vp-add-dataset -o --tag-name=clovr_metagenomics_noorfs_map /opt/hudson/Metagenomic_data/Twins.small.meta

DATE=`date +"%m-%d-%Y-%T" | sed -e 's/:/_/g'`

vp-describe-protocols --config-from-protocol=clovr_metagenomics_noorfs \
    -c input.FASTA_TAG=clovr_metagenomics_noorfs_fasta \
    -c input.MAPPING_TAG=clovr_metagenomics_noorfs_map \
    -c pipeline.PIPELINE_NAME=clovr_metagenomics_noorfs_${DATE} \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    > /tmp/$$.pipeline.conf.${DATE}

TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-name clovr_metagenomics_noorfs_$$_${DATE} --pipeline clovr_wrapper --pipeline-config /tmp/$$.pipeline.conf.${DATE}`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?




