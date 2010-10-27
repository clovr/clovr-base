#!/bin/bash 

set -e
source /root/clovrEnv.sh

# Run PyCogent's all_tests.py script to invoke all unit tests
python /opt/hudson/PyCogent/alltests.py
