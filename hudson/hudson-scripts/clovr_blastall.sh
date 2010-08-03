#!/bin/bash
set -e
source /root/clovrEnv.sh

tagData.py --tag-name=NC_000964_peps /opt/hudson/NC_000964/NC_000964.faa

tagData.py --tag-name=NC_000964_blastpdb /opt/hudson/NC_000964/NC_000964.faa*

DATE=`date +"%m-%d-%Y-%T"`

cp /opt/hudson/clovr_blastall.config /tmp/pipeline.conf

sed -i -e "s/\${DATE}/$DATE/" /tmp/pipeline.conf

TASK_NAME=`runPipeline.py --print-task-name --pipeline clovr_wrapper --name local -n blastall -- --CONFIG_FILE=/tmp/pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

taskStatus.py --name local --exit-code --block $TASK_NAME

exit $?
