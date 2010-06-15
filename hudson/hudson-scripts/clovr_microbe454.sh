#! /bin/bash

source /root/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

cp /opt/hudson/clovr_microbe454.config /tmp/pipeline.conf

sed -i -e "s/\${DATE}/$DATE/" /tmp/pipeline.conf

bootStrapKeys.py

runPipeline.py --name local --pipeline-name microbe-$DATE --pipeline=clovr_wrapper -- --CONFIG_FILE=/tmp/pipeline.conf 

