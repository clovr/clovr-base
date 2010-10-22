#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

vp-add-dataset -o --tag-name=NC_000964_peps -m format_type=aa_FASTA /opt/hudson/NC_000964/NC_000964.faa

vp-add-dataset -o --tag-name=NC_000964_blastpdb -m format_type=aa_blastdb /opt/hudson/NC_000964/NC_000964.faa*

DATE=`date +"%m-%d-%Y-%T"`

vp-describe-protocols --config-from-protocol=clovr_search \
    -c input.INPUT_TAG=NC_000964_peps \
    -c input.REF_DB_TAG=NC_000964_blastpdb \
    -c input.PIPELINE_NAME=clovr_search_${DATE} \
    -c misc.PROGRAM=blastp \
    > /tmp/$$.pipeline.conf

TASK_NAME=`vp-run-pipeline --print-task-name --pipeline clovr_wrapper --name local -n clovr_search_$$ -- --CONFIG_FILE=/tmp/$$.pipeline.conf`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?
