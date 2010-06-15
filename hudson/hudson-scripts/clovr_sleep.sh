#!/bin/bash

source /root/clovrEnv.sh

runPipeline.py --pipeline clovr_wrapper --name local -n clovrsleep -- --CONFIG_FILE=/opt/hudson/clovr_sleep.config
