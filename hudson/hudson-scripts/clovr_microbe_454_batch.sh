#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

wget -O /mnt/user_data/Acinetobacter454.tar.gz http://cb2.igs.umaryland.edu/clovr/Public_Benchmarks/CloVR-Microbe/Acinetobacter454/Acinetobacter454.tar.gz 

tar xfv /mnt/user_data/Acinetobacter454.tar.gz

vp-add-dataset -o --tag-name=clovr_microbe_454_batch /opt/hudson/clovr_microbe_454_batch.tab 
vp-add-dataset -o --tag-name=abacter250k /mnt/user_data/Acinetobacter454.sff

TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-config /opt/hudson/clovr_microbe_454_batch.config --overwrite`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?

