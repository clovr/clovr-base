#!/bin/bash
set -e
source /opt/workflow-sforge/exec_env.bash 

CreateWorkflow -c /opt/workflow-sforge/examples/distributed/ls-commands-distributed.ini -t /opt/workflow-sforge/examples/distributed/ls-commands-distributed-parallel-template.xml -i test.xml

RunWorkflow -i test.xml