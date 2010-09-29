#!/bin/bash
set -e
source /root/clovrEnv.sh

vp-add-dataset -o --tag-name=clovr_16S_multi_input /opt/hudson/16S_data/A.fasta /opt/hudson/16S_data/B.fasta /opt/hudson/16S_data/C.fasta /opt/hudson/16S_data/D.fasta
vp-add-dataset -o --tag-name=clovr_16S_multi_mapping /opt/hudson/16S_data/IGS.multi.meta

DATE=`date +"%m-%d-%Y-%T"`

vp-describe-protocols --config-from-protocol=clovr_16S \
    -c input.FASTA_TAG=clovr_16S_multi_input \
    -c input.MAPPING_TAG=clovr_16S_multi_mapping \
    -c input.PIPELINE_NAME=clovr_16S_multi_${DATE} \
    > /tmp/pipeline.conf

TASK_NAME=`runPipeline.py --name local  --print-task-name --pipeline-name clovr_16S_multi_$$ --pipeline=clovr_wrapper -- --CONFIG_FILE=/tmp/pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

taskStatus.py --name local --exit-code --block $TASK_NAME

exit $?




