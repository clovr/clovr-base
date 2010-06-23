#! /bin/bash

saved=`ls /opt/clovr_pipelines/workflow/project_saved_templates`
for each in $saved
do
    temp=`ls /opt/clovr_pipelines/workflow/project_saved_templates/$each | grep .config`
    for config in $temp
    do
	cat /opt/clovr_pipelines/workflow/project_saved_templates/$each/$config | grep -iE "(TEMPLATE_XML|ITERATOR1_XML)"
    done
done
