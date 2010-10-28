#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%y-%T"`

vp-describe-protocols --config-from-protocol=clovr_pangenome \
    -c input.GENBANK_TAG=bifidobacter_genbank_tag \
    -c input.OUTPUT_PREFIX=bifidobacter \
    -c input.ORGANISM="Bifidobacter sp" \
    -c input.PIPELINE_NAME=pangenome_${DATE} \
    > /tmp/$$.pipeline.conf

vp-add-dataset --tag-name=bifidobacter_genbank_tag -o /opt/hudson/pangenome_data/bifidobacter_genbank_files/Bifidobacterium_adolescentis_ATCC_15703/AP009256.gbk /opt/hudson/pangenome_data/bifidobacter_genbank_files/Bifidobacterium_longum_infantis_ATCC_15697/CP001095.gbk

TASK_NAME=`runPipeline.py --name local --print-task-name --pipeline-name clovr_pangenome_$$ --pipeline=clovr_wrapper --pipeline-config=/tmp/$$.pipeline.conf`

if [ "$?" == "1" ]; then
	echo "runPipeline.py failed to run"
	exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?
