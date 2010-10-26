#!/bin/bash
set -e
source /opt/workflow-sforge/exec_env.bash 

cd /tmp
mkdir /tmp/$$
cd /tmp/$$
touch file1 file2 file3

CreateWorkflow -c /opt/workflow-sforge/examples/distributed/ls-commands-distributed.ini -t /opt/workflow-sforge/examples/distributed/ls-commands-distributed-parallel-template.xml -i test.$$.xml

RunWorkflow -i test.$$.xml