#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%y-%T"`

vp-describe-protocols --config-from-protocol=clovr_comparative \
    -c input.GENBANK_TAG=bifidobacter_genbank_tag \
    -c params.OUTPUT_PREFIX=bifidobacter \
    -c params.ORGANISM="Bifidobacter sp" \
    -c pipelines.PIPELINE_NAME=comparative_${DATE} \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    > /tmp/$$.pipeline.conf.${DATE}

vp-add-dataset --tag-name=bifidobacter_genbank_tag -o /opt/hudson/pangenome_data/bifidobacter_genbank_files/Bifidobacterium_adolescentis_ATCC_15703/AP009256.gbk /opt/hudson/pangenome_data/bifidobacter_genbank_files/Bifidobacterium_longum_infantis_ATCC_15697/CP001095.gbk

TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-name clovr_comparative_$$_${DATE} --pipeline clovr_wrapper --pipeline-config /tmp/$$.pipeline.conf.${DATE}`

if [ "$?" == "1" ]; then
	echo "vp-run-pipeline failed to run"
	exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?
