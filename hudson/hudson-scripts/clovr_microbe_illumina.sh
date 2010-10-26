#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

cp /opt/hudson/clovr_microbe_illumina.config /tmp/$$.pipeline.conf

sed -i -e "s/\${DATE}/$DATE/" /tmp/$$.pipeline.conf

vp-add-dataset --tag-name=hudson_test_tag /opt/hudson/illumina_data/partial_reads_1.fastq /opt/hudson/illumina_data/partial_reads_2.fastq -o

TASK_NAME=`runPipeline.py --name local  --print-task-name --pipeline-name microbe_illumina-$DATE --pipeline=clovr_wrapper -- --CONFIG_FILE=/tmp/$$.pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?




