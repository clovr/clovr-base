#!/bin/bash

temp=`ls /opt/clovr_pipelines/workflow/project_saved_templates/$1 | grep .config`
for config in $temp
do
    echo $config
    grep -E "(^\\$;TEMPLATE_XML|^\\$;ITERATOR1_XML)" /opt/clovr_pipelines/workflow/project_saved_templates/$1/$config > /tmp/temp.txt
    grep -E '^\$;ITERATOR1' /opt/clovr_pipelines/workflow/project_saved_templates/$1/$config | grep -v "_XML" | sed "s/ //g" > /tmp/temp2.txt
    iterator=`cat /tmp/temp2.txt`
    iterator=${iterator:14}
    component=`echo $config | perl -ne 'if(/([^\.]+)/){print "$1\n" }'`
    
    while read line     
    do
	
	echo $line | sed -e "s/$;TEMPLATE_XML$; = $;DOCS_DIR$;/\/opt\/ergatis\/docs/g" |  sed -e "s/$;TEMPLATE_XML$;=$;DOCS_DIR$;/\/opt\/ergatis\/docs/g" |  sed -e "s/$;ITERATOR1_XML$;=$;DOCS_DIR$;/\/opt\/ergatis\/docs/g" |  sed -e "s/$;ITERATOR1_XML$; = $;DOCS_DIR$;/\/opt\/ergatis\/docs/g" | sed -e "s/$;COMPONENT_NAME$;/$component/g" | sed -e "s/$;ITERATOR1$;/$iterator/g" >> /tmp/temp3.txt
    done < /tmp/temp.txt
    
done
fail=0
XML=`cat /tmp/temp3.txt | sort -u`
for i in $XML

do
    if [ ! -f $i ]
    then
	echo file does not exist!
	fail=1
    fi
    grep executable $i

done | sort -u | cut -f 2 -d '>' | cut -f 1 -d '<'

if [ $fail==1 ]; then
    echo error occured!
    exit 1
fi
#rm /tmp/{temp.txt,temp2.txt,temp3.txt}