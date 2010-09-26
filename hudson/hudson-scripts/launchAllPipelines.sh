#!/bin/bash
set -e
find /var/lib/hudson/jobs/ -maxdepth 1 -name "[[:digit:]]*" -printf "%f\n" | sort -n | grep -i -P 'pipeline$' > /tmp/pipelinejobs.txt

ip=`hostname`
#ip=${ip:6}
#ip=`echo $ip | sed -e 's/-/./g'` 

#Launch non pipeline jobs first
while read line 
do  
    curl `echo "http://$ip:8888/job/$line/build" | sed -e 's/ /\%20/g'`
done < /tmp/pipelinejobs.txt

