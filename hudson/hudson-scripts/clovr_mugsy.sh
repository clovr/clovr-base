#!/bin/bash
set -e
source /root/clovrEnv.sh

DATE=`date +"%m-%d-%y-%T"`

cp /opt/hudson/clovr_mugsy.config /tmp/pipeline.conf

sed -i -e "s/\${DATE}/$DATE/" /tmp/pipeline.conf

tagData.py --tag-name=hudson_genbank_tag -o /opt/hudson/pangenome_data/bifidobacter_genbank_files/Bifidobacterium_adolescentis_ATCC_15703/AP009256.gbk /opt/hudson/pangenome_data/bifidobacter_genbank_files/Bifidobacterium_longum_infantis_ATCC_15697/CP001095.gbk

TASK_NAME=`runPipeline.py --name local --print-task-name --pipeline-name clovr_mugsy-$DATE --pipeline=clovr_wrapper -- --CONFIG_FILE=/tmp/pipeline.conf`
if [ "$?" == "1" ]; then
	echo "runPipeline.py failed to run"
	exit 1
fi

taskStatus.py --name local --exit-code --block $TASK_NAME

exit $?
