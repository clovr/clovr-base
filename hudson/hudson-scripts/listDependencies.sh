#! /bin/bash

saved=`ls /opt/clovr_pipelines/workflow/project_saved_templates`
for each in $saved
do
    temp=`ls /opt/clovr_pipelines/workflow/project_saved_templates/$each | grep .config`
    for config in $temp
    do
	grep -E "(^\\$;TEMPLATE_XML|^\\$;ITERATOR1_XML)" /opt/clovr_pipelines/workflow/project_saved_templates/$each/$config > /tmp/temp.txt
	component=`echo $config | perl -ne 'if(/([^\.]+)/){print "$1\n" }'`
	while read line     
	do
	    echo $line | sed -e "s/$;TEMPLATE_XML$; = $;DOCS_DIR$;/\/opt\/ergatis\/docs/g" |  sed -e "s/$;TEMPLATE_XML$;=$;DOCS_DIR$;/\/opt\/ergatis\/docs/g" |  sed -e "s/$;ITERATOR1_XML$;=$;DOCS_DIR$;/\/opt\/ergatis\/docs/g" |  sed -e "s/$;ITERATOR1_XML$; = $;DOCS_DIR$;/\/opt\/ergatis\/docs/g"
	done < /tmp/temp.txt
	
    done
done
