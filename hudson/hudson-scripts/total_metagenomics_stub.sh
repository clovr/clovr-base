#! /bin/bash

source /root/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

cp /opt/hudson/total_metagenomics_stub.config /tmp/pipeline.conf

sed -i -e "s/\${DATE}/$DATE/" /tmp/pipeline.conf

bootStrapKeys.py


TASK_NAME=`runPipeline.py --name local  --print-task-name --pipeline-name microbe-$DATE --pipeline=clovr_wrapper -- --CONFIG_FILE=/tmp/pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

taskStatus.py --name local --exit-code --block $TASK_NAME

exit $?




