#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T" | sed -e 's/:/_/g'`

vp-describe-protocols --config-from-protocol=clovr_microbe454 \
    -c input.INPUT_SFF_TAG=hudson_sff_test \
    -c params.OUTPUT_PREFIX=BD413_mini \
    -c params.ORGANISM="Acinetobacter baylii" \
    -c params.SKIP_BANK=true \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    -c pipeline.PIPELINE_DESC="Hudson CloVR Microbe 454 Test" \
    > /tmp/$$.pipeline.conf.${DATE}

vp-add-dataset --tag-name=hudson_sff_test /opt/hudson/BD413_wt_contig170.sff -o

TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-config /tmp/$$.pipeline.conf.${DATE} --overwrite`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?




