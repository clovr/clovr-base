#! /bin/bash

saved=`ls /opt/clovr_pipelines/workflow/project_saved_templates`
for each in $saved
do
    temp=`ls /opt/clovr_pipelines/workflow/project_saved_templates/$each | grep .config`
    for config in $temp
    do
	grep -E "(^\\$;TEMPLATE_XML|^\\$;ITERATOR1_XML)" /opt/clovr_pipelines/workflow/project_saved_templates/$each/$config > /tmp/temp.txt
 	grep -E '^\$;ITERATOR1' /opt/clovr_pipelines/workflow/project_saved_templates/$each/$config | grep -v "_XML" | sed "s/ //g" > /tmp/temp2.txt
	iterator=`cat /tmp/temp2.txt`
	echo $iterator
	#component=`echo $config | perl -ne 'if(/([^\.]+)/){print "$1\n" }'`
	
#	while read line     
#	do

	  #  echo $line
	#    
	#    echo $line | sed -e "s/$;TEMPLATE_XML$; = $;DOCS_DIR$;/\/opt\/ergatis\/docs/g" |  sed -e "s/$;TEMPLATE_XML$;=$;DOCS_DIR$;/\/opt\/ergatis\/docs/g" |  sed -e "s/$;ITERATOR1_XML$;=$;DOCS_DIR$;/\/opt\/ergatis\/docs/g" |  sed -e "s/$;ITERATOR1_XML$; = $;DOCS_DIR$;/\/opt\/ergatis\/docs/g" | sed -e "s/$;COMPONENT_NAME$;/$component/g"
#	done < /tmp/temp.txt
	
    done
done
