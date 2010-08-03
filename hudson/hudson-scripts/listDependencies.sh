#!/bin/bash
set -e
saved=`ls /opt/clovr_pipelines/workflow/project_saved_templates`
for each in $saved
do
    temp=`ls /opt/clovr_pipelines/workflow/project_saved_templates/$each | grep .config`
    for config in $temp
    do
	grep -E "(^\\$;TEMPLATE_XML|^\\$;ITERATOR1_XML)" /opt/clovr_pipelines/workflow/project_saved_templates/$each/$config > /tmp/temp.txt
 	grep -E '^\$;ITERATOR1' /opt/clovr_pipelines/workflow/project_saved_templates/$each/$config | grep -v "_XML" | sed "s/ //g" > /tmp/temp2.txt
	iterator=`cat /tmp/temp2.txt`
	iterator=${iterator:14}
	component=`echo $config | perl -ne 'if(/([^\.]+)/){print "$1\n" }'`
	
	while read line     
	do
	    
	    echo $line | sed -e "s/$;TEMPLATE_XML$; = $;DOCS_DIR$;/\/opt\/ergatis\/docs/g" |  sed -e "s/$;TEMPLATE_XML$;=$;DOCS_DIR$;/\/opt\/ergatis\/docs/g" |  sed -e "s/$;ITERATOR1_XML$;=$;DOCS_DIR$;/\/opt\/ergatis\/docs/g" |  sed -e "s/$;ITERATOR1_XML$; = $;DOCS_DIR$;/\/opt\/ergatis\/docs/g" | sed -e "s/$;COMPONENT_NAME$;/$component/g" | sed -e "s/$;ITERATOR1$;/$iterator/g" >> /tmp/temp3.txt
	done < /tmp/temp.txt
	
    done
done

XML=`cat /tmp/temp3.txt | sort -u`
for i in $XML
do
    cat `echo $i` | grep executable
done

rm /tmp/{temp.txt,temp2.txt,temp3.txt}