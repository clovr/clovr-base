#!/bin/bash 

filelist=`find /opt/clovr_pipelines/workflow/project_saved_templates/ -name "*.*.config" | grep -v clovr_wrapper`
i=0
error=0
for f in $filelist
do
    echo "Checkin $f"
    cp --force $f /tmp/$$.$i.user.config
    perl -pi -e 's|(..PROJECT_CONFIG..)\s*=.*|$1=/mnt/projects/clovr/workflow/project.config|' /tmp/$$.$i.user.config
    /opt/ergatis/bin/replace_config_keys --template_conf /tmp/$$.$i.user.config --output_conf /tmp/$$.$i.final.config --keys=PIPELINEID=0,PIPELINE_XML=/tmp/$$.$i.pipeline.xml,COMPONENT_XML=/tmp/$$.$i.component.xml
    if [ $? != 0 ]
    then
	echo "ERROR in $f"
	error=1
    fi
    /opt/ergatis/bin/replace_template_keys --component_conf /tmp/$$.$i.final.config --template_xml_conf_key TEMPLATE_XML --output_xml /tmp/$$.$i.component.xml
    if [ $? != 0 ]
    then
	echo "ERROR in $f"
	error=1
    fi
    i=`expr $i + 1`
done

if [ "$error" = 0 ]
then
    exit 0;
else
    exit 1;
fi
