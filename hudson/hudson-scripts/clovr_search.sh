#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

vp-add-dataset -o --tag-name=NC_000964_peps -m format_type=aa_FASTA /opt/hudson/NC_000964/NC_000964.faa

vp-add-dataset -o --tag-name=NC_000964_blastpdb -m format_type=aa_blastdb /opt/hudson/NC_000964/NC_000964.faa*

DATE=`date +"%m-%d-%Y-%T" | sed -e 's/:/_/g'`

vp-describe-protocols --config-from-protocol=clovr_search \
    -c input.INPUT_TAG=NC_000964_peps \
    -c input.REF_DB_TAG=NC_000964_blastpdb \
    -c pipeline.PIPELINE_NAME=clovr_search_${DATE} \
    -c params.PROGRAM=blastp \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    > /tmp/$$.pipeline.conf.${DATE}

TASK_NAME=`vp-run-pipeline --print-task-name --pipeline clovr_wrapper --pipeline-name clovr_search_$$_${DATE} --pipeline-config /tmp/$$.pipeline.conf.${DATE}`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?
