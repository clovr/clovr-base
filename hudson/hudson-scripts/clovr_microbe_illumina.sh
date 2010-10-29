#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

vp-add-dataset --tag-name=clovr_microbe_illumina_tag /opt/hudson/illumina_data/partial_reads_1.fastq /opt/hudson/illumina_data/partial_reads_2.fastq -o

vp-describe-protocols --config-from-protocol=clovr_microbe_illumina \
    -c input.SHORT_PAIRED_TAGS=clovr_microbe_illumina_tag \
    -c input.PIPELINE_NAME=clovr_microbe_illumina_${DATE} \
    > /tmp/$$.pipeline.conf


TASK_NAME=`runPipeline.py --name local  --print-task-name --pipeline-name microbe_illumina-$DATE --pipeline=clovr_wrapper --pipeline-config=/tmp/$$.pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?




