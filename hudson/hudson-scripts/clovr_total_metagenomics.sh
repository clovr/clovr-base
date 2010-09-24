#!/bin/bash
set -e 
source /root/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

# Need to tag our data prior to kicking off the pipeline 
vp-add-dataset --tag-name=clovr_total_metagenomics_hudson /opt/hudson/MOMSP_454Reads_Region1_subset2.fasta -o

cp /opt/hudson/clovr_total_metagenomics.config /tmp/pipeline.conf
sed -i -e "s/\${DATE}/$DATE/" /tmp/pipeline.conf

TASK_NAME=`runPipeline.py --name local  --print-task-name --pipeline-name microbe-$DATE --pipeline=clovr_wrapper -- --CONFIG_FILE=/tmp/pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

taskStatus.py --name local --exit-code --block $TASK_NAME

exit $?
