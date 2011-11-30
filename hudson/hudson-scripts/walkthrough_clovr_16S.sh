#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

if [ ! -d "/mnt/staging/data/infant_gut_data_16S" ]; then
	vp-add-dataset --tag-name=infant_gut_data_16S -o --url=http://cb2.igs.umaryland.edu/clovr/Public_Benchmarks/CloVR-16S/InfantGutMicrobiome/InfantGut16S.tar.gz --expand

	vp-transfer-dataset --tag-name=infant_gut_data_16S
fi

vp-add-dataset -o --tag-name=clovr_16S_single_input_$2 /mnt/staging/data/infant_gut_data_16S/InfantGut16S.fasta
vp-add-dataset -o --tag-name=clovr_16S_single_mapping /mnt/staging/data/infant_gut_data_16S/InfantGut16S.map

DATE=`date +"%m-%d-%Y-%T" | sed -e 's/:/_/g'`

vp-describe-protocols --config-from-protocol=clovr_16S \
    -c input.FASTA_TAG=clovr_16S_single_input_$2 \
    -c input.MAPPING_TAG=clovr_16S_single_mapping \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    -c cluster.TERMINATE_ONFINISH=false \
    -c pipeline.PIPELINE_DESC="Hudson Clovr 16S Single Fasta Test $2" \
    > /tmp/$$.pipeline.conf.${DATE}

TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-config /tmp/$$.pipeline.conf.${DATE} --overwrite`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?




