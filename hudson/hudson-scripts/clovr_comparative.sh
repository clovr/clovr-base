#!/bin/bash
set -e
source /root/clovrEnv.sh

DATE=`date +"%m-%d-%y-%T"`

cp /opt/hudson/clovr_comparative.config /tmp/pipeline.conf

sed -i -e "s/\${DATE}/$DATE/" /tmp/pipeline.conf

tagData.py --tag-name=hudson_genbank_tag -o /opt/hudson/comparative_data/Chlamydophila_pneumoniae_AR39/NC_002179.gbk /opt/hudson/comparative_data/Chlamydophila_pneumoniae_AR39/NC_002180.gbk

TASK_NAME=`runPipeline.py --name local --print-task-name --pipeline-name clovr_comparative-$DATE --pipeline=clovr_wrapper -- --CONFIG_FILE=/tmp/pipeline.conf`
if [ "$?" == "1" ]; then
	echo "runPipeline.py failed to run"
	exit 1
fi

taskStatus.py --name local --exit-code --block $TASK_NAME

exit $?
