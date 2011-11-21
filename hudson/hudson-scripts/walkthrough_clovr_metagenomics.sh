#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

vp-add-dataset -o --tag-name=clovr_metagenomics_noorfs_fasta_$2 /opt/hudson/walkthrough_datasets/clovr_metagenomics/fastas/*.fasta

vp-add-dataset -o --tag-name=clovr_metagenomics_noorfs_map /opt/hudson/walkthrough_datasets/clovr_metagenomics/InfantGutMetagenome.map

DATE=`date +"%m-%d-%Y-%T" | sed -e 's/:/_/g'`

vp-describe-protocols --config-from-protocol=clovr_metagenomics_noorfs \
    -c input.FASTA_TAG=clovr_metagenomics_noorfs_fasta_$2 \
    -c input.MAPPING_TAG=clovr_metagenomics_noorfs_map \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    -c cluster.TERMINATE_ONFINISH=false \
    -c pipeline.PIPELINE_DESC="Hudson CloVR Metagenomics Noorfs Test $2" \
    > /tmp/$$.pipeline.conf.${DATE}

TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-config /tmp/$$.pipeline.conf.${DATE} --overwrite`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?




