#!/bin/bash
set -e
source /opt/workflow-sforge/exec_env.bash 

CreateWorkflow -c /opt/workflow-sforge/examples/local/ls-commands.ini -t /opt/workflow-sforge/examples/local/ls-commands-template.xml -i test.xml

RunWorkflow -i test.xml