#!/bin/bash
set -e
source /root/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

cp /opt/hudson/clovr_microbe454.config /tmp/pipeline.conf

sed -i -e "s/\${DATE}/$DATE/" /tmp/pipeline.conf

tagData.py --tag-name=hudson_sff_test /opt/hudson/BD413_wt_contig170.sff -o

TASK_NAME=`runPipeline.py --name local  --print-task-name --pipeline-name microbe-$DATE --pipeline=clovr_wrapper -- --CONFIG_FILE=/tmp/pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

taskStatus.py --name local --exit-code --block $TASK_NAME

exit $?




