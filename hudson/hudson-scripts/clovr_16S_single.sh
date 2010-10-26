#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

vp-add-dataset -o --tag-name=clovr_16S_single_input /opt/hudson/16S_data/AMP_Lung.small.fasta
vp-add-dataset -o --tag-name=clovr_16S_single_mapping /opt/hudson/16S_data/IGS.qmap

DATE=`date +"%m-%d-%Y-%T"`

vp-describe-protocols --config-from-protocol=clovr_16S \
    -c input.FASTA_TAG=clovr_16S_single_input \
    -c input.MAPPING_TAG=clovr_16S_single_mapping \
    -c input.PIPELINE_NAME=clovr_16S_single_${DATE} \
    > /tmp/$$.pipeline.conf

TASK_NAME=`runPipeline.py --name local  --print-task-name --pipeline-name clovr_16S_single_$$ --pipeline=clovr_wrapper -- --CONFIG_FILE=/tmp/$$.pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?




