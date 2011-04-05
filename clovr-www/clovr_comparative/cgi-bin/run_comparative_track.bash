#!/bin/bash

set -e 

my_date=$(date +"%m-%d-%y_%H:%M:%S")
my_date="${my_date}_$$"
my_tag_name="comparative_track_${my_date}"
my_wrapper_name="comparative_wrapper_${my_date}"
my_worker_name="comparative_worker_${my_date}"
my_temp_file="/tmp/comparative_track_${my_date}.config"

touch "$my_temp_file"

track_name=${1}

shift

vp-add-dataset --tag-name ${my_tag_name} -o $(echo "$@") 

vp-describe-protocols -p ${track_name} -c input.GENBANK_TAG=${my_tag_name} -c pipeline.PIPELINE_NAME=${my_worker_name} > $my_temp_file

run_pipeline="vp-run-pipeline --print-task-name --pipeline clovr_wrapper --pipeline-name ${my_wrapper_name} --pipeline-config $my_temp_file"

#echo $run_pipeline

task_name=$($run_pipeline)

if [ "$?" -ne 0 ]; then
	echo 'vp-run-pipeline failed to run'
	exit 1
fi

echo $task_name

exit $?
