#! /bin/bash

source /root/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

cp  /opt/hudson/BD413_wt_contig170.conf /tmp/pipeline.conf

sed -i -e "s/\${DATE}/$DATE/" /tmp/pipeline.conf

bootStrapKeys.py

run_prokaryotic_pipeline.pl --prok_conf=/tmp/pipeline.conf
