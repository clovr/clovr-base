#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T" | sed -e 's/:/_/g'`

if [ ! -d "/mnt/staging/data/ecoli_microbe_454_data" ]; then
	vp-add-dataset -o --tag-name=ecoli_microbe_454_data --url=http://cb2.igs.umaryland.edu/clovr/Public_Benchmarks/CloVR-Microbe/Ecoli454/Ecoli454_500k.tar.gz --expand

	vp-transfer-dataset --tag-name=ecoli_microbe_454_data
fi

vp-add-dataset --tag-name=hudson_sff_walkthrough_test_with_ecoli_$2 /mnt/staging/data/ecoli_microbe_454_data/Ecoli454.sff -o

vp-describe-protocols --config-from-protocol=clovr_microbe454 \
    -c input.INPUT_SFF_TAG=hudson_sff_walkthrough_test_with_ecoli_$2 \
    -c params.OUTPUT_PREFIX=BD413_mini \
    -c params.ORGANISM="Escherichia coli" \
    -c params.SKIP_BANK=true \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    -c cluster.TERMINATE_ONFINISH=false \
    -c pipeline.PIPELINE_DESC="Hudson CloVR Microbe 454 walk thorugh Test $2" \
    > /tmp/$$.pipeline.conf.${DATE}

TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-config /tmp/$$.pipeline.conf.${DATE} --overwrite`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?




