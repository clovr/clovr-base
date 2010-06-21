#! /bin/bash

ls /var/lib/hudson/jobs > /tmp/jobs.txt

ip=`hostname`
ip=${ip:6}
ip=`echo $ip | sed -e 's/-/./g'` 

while read line 
do  
   curl `echo "http://$ip:8888/job/$line/build" | sed -e 's/ /\%20/g'`
done < /tmp/jobs.txt
