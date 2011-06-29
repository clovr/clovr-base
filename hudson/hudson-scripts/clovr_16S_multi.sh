#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

vp-add-dataset -o --tag-name=clovr_16S_multi_input /opt/hudson/16S_data/A.fasta /opt/hudson/16S_data/B.fasta /opt/hudson/16S_data/C.fasta /opt/hudson/16S_data/D.fasta
vp-add-dataset -o --tag-name=clovr_16S_multi_mapping /opt/hudson/16S_data/IGS.multi.meta

DATE=`date +"%m-%d-%Y-%T" | sed -e 's/:/_/g'`

vp-describe-protocols --config-from-protocol=clovr_16S \
    -c input.FASTA_TAG=clovr_16S_multi_input \
    -c input.MAPPING_TAG=clovr_16S_multi_mapping \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    -c pipeline.PIPELINE_DESC="Hudson Clovr 16S Multi test" \
    > /tmp/$$.pipeline.conf.${DATE}

TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-config /tmp/$$.pipeline.conf.${DATE} --overwrite`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?




