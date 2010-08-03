#!/bin/bash
set -e
ls /var/lib/hudson/jobs > /tmp/jobs.txt

ip=`hostname`
ip=${ip:6}
ip=`echo $ip | sed -e 's/-/./g'` 

while read line 
do  
     
    if [ "$line" == "00 Launch all jobs" ]; then
	echo "self"
    else
	curl `echo "http://$ip:8888/job/$line/build" | sed -e 's/ /\%20/g'`
    fi
done < /tmp/jobs.txt
