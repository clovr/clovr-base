#!/bin/bash

set -e 

my_date=$(date +"%m-%d-%y_%H:%M:%S")
my_date="${my_date}_$$"
my_tag_name="comparative_track_${my_date}"
my_wrapper_name="comparative_wrapper_${my_date}"
my_worker_name="comparative_worker_${my_date}"
my_temp_file="/tmp/comparative_track_${my_date}.config"

track_name=$1

shift

cd /mnt

umask 000

touch "$my_temp_file"

declare -a my_links

for file in "$@"; do
	my_links=(${my_links[*]} "ftp://${file} ")
done

wget -r -t 10 -N $(echo "${my_links[*]}")

vp-add-dataset --tag-name ${my_tag_name} -o $(echo "$@") 

vp_describe_command="vp-describe-protocols -p ${track_name} -c input.GENBANK_TAG=${my_tag_name} -c pipeline.PIPELINE_NAME=${my_worker_name}"

#echo $vp_describe_command

$vp_describe_command 1>$my_temp_file

run_pipeline="vp-run-pipeline --print-task-name --pipeline clovr_wrapper --pipeline-name ${my_wrapper_name} --pipeline-config $my_temp_file"

#echo $run_pipeline

task_name=$($run_pipeline)

if [ "$?" -ne 0 ]; then
	echo 'vp-run-pipeline failed to run'
	exit 1
fi

echo $task_name

exit $?