#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T" | sed -e 's/:/_/g'`

if [ ! -d "/mnt/staging/data/ecoli_microbe_illumina_data" ]; then
	vp-add-dataset -o --tag-name=ecoli_microbe_illumina_data --url=http://cb2.igs.umaryland.edu/clovr/Public_Benchmarks/CloVR-Microbe/EcoliIllumina/EcoliIlluminaPairedEnd.tar.gz --expand

	vp-transfer-dataset --tag-name=ecoli_microbe_illumina_data
fi

vp-add-dataset -o --tag-name=clovr_microbe_illumina_walkthrough_tag_with_ecoli_$2 /mnt/staging/data/ecoli_microbe_illumina_data/illumina_4M_1.fastq /mnt/staging/data/ecoli_microbe_illumina_data/illumina_4M_2.fastq 

vp-describe-protocols --config-from-protocol=clovr_microbe_illumina \
    -c input.SHORT_PAIRED_TAG=clovr_microbe_illumina_walkthrough_tag_with_ecoli_$2 \
    -c params.OUTPUT_PREFIX=test \
    -c params.ORGANISM="Eschirecia coli" \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    -c cluster.TERMINATE_ONFINISH=false \
    -c pipeline.PIPELINE_DESC="Hudson CloVR Micorbe Illumina walkthrough Test $2" \
    > /tmp/$$.pipeline.conf.${DATE}


TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-config /tmp/$$.pipeline.conf.${DATE} --overwrite`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?




