#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

vp-add-dataset -o --tag-name=hlgt_complete_$1 -m format_type=remote_file_list /mnt/user_data/all_sra_sorted_by_size.txt

DATE=`date +"%m-%d-%Y-%T" | sed -e 's/:/_/g'`

vp-describe-protocols --config-from-protocol=clovr_lgt_wrapper \
    -c input.INPUT_TAG=hlgt_complete_$1 \
    -c input.LINES_PER_FILE=10 \
    -c input.REF_TAG1=test_lgt_wrapper_A2D_ref,test_lgt_wrapper_E2P_ref,test_lgt_wrapper_R2Z_ref \
    -c input.REF_TAG2=test_lgt_wrapper_hg19_ref \
    -c input.DECRYPT_SCRIPT=/mnt/user_data/decrypt_lgt.sh \
    -c input.NUM_RETRIES=10 \
    -c input.REMOTE_OUTPUT=/diag/HLGTDBGAP/bwa_output/ \
    -c input.REMOTE_HOST=diagmaster.igs.umaryland.edu \
    -c input.REMOTE_USER=driley \
    -c input.MAX_PIPES=5 \
    -c cluster.CLUSTER_CREDENTIAL=$1 \
    -c cluster.TERMINATE_ONFINISH=false \
    -c pipeline.PIPELINE_DESC="HLGT Pipeline $1" \
    > /tmp/$$.pipeline.conf.${DATE}

TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-config /tmp/$$.pipeline.conf.${DATE} --overwrite`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi
echo $TASK_NAME
vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?
