#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

vp-add-dataset -o --tag-name=obese_lean_twin_gut_metagenomics_data --url=http://cb2.igs.umaryland.edu/clovr/Public_Benchmarks/CloVR-Metagenomics/ObeseLeanTwinGut/ObeseLeanTwinGut.tar.gz --expand

vp-transfer-dataset --tag-name=obese_lean_twin_gut_metagenomics_data

vp-add-dataset -o --tag-name=clovr_metagenomics_noorfs_fasta_$2 /mnt/staging/data/obese_lean_twin_gut_metagenomics_data/fastas/*.fna

vp-add-dataset -o --tag-name=clovr_metagenomics_noorfs_map /mnt/staging/data/obese_lean_twin_gut_metagenomics_data/ObeseLeanTwin.map

DATE=`date +"%m-%d-%Y-%T" | sed -e 's/:/_/g'`

vp-describe-protocols --config-from-protocol=clovr_metagenomics_noorfs \
    -c input.FASTA_TAG=clovr_metagenomics_noorfs_fasta_$2 \
    -c input.MAPPING_TAG=clovr_metagenomics_noorfs_map \
    -c cluster.CLUSTER_NAME=$1 \
    -c cluster.CLUSTER_CREDENTIAL=$2 \
    -c cluster.TERMINATE_ONFINISH=false \
    -c pipeline.PIPELINE_DESC="Hudson CloVR Metagenomics Noorfs Test $2" \
    > /tmp/$$.pipeline.conf.${DATE}

TASK_NAME=`vp-run-pipeline --print-task-name --pipeline-config /tmp/$$.pipeline.conf.${DATE} --overwrite`

if [ "$?" == "1" ]; then
    echo "vp-run-pipeline failed to run"
    exit 1
fi

vp-describe-task --name local --exit-code --block $TASK_NAME

exit $?




