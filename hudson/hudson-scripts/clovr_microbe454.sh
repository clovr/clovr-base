#!/bin/bash
exit 1
set -e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

vp-describe-protocols --config-from-protocol=clovr_microbe454 \
    -c input.INPUT_SFF_TAG=hudson_sff_test \
    -c input.OUTPUT_PREFIX=BD413_mini \
    -c input.ORGANISM="Acinetobacter baylii" \
    -c input.SKIP_BANK=1 \
    -c input.PIPELINE_NAME=illumina_${DATE} \
    > /tmp/$$.pipeline.conf

vp-add-dataset --tag-name=hudson_sff_test /opt/hudson/BD413_wt_contig170.sff -o

TASK_NAME=`runPipeline.py --name local  --print-task-name --pipeline-name clovr_microbe454_$$ --pipeline=clovr_wrapper --pipeline-config=/tmp/$$.pipeline.conf`

if [ "$?" == "1" ]; then
    echo "runPipeline.py failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?




