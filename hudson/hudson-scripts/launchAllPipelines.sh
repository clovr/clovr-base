#!/bin/bash
set -e

touch /tmp/pipelinejobs.$$.txt
if [ "$1" = "true" ]
then
	find /var/lib/hudson/jobs/ -maxdepth 1 -name "[[:digit:]]*" -printf "%f\n" | sort -n | grep -i -P 'pipeline$' > /tmp/pipelinejobs.$$.txt
fi

if [ "$2" = "true" ]
then
	find /var/lib/hudson/jobs/ -maxdepth 1 -name "DIAG*" -printf "%f\n" | sort -n | grep -i -P 'pipeline$' >> /tmp/pipelinejobs.$$.txt
fi

if [ "$3" = "true" ]
then
        find /var/lib/hudson/jobs/ -maxdepth 1 -name "EC2*" -printf "%f\n" | sort -n | grep -i -P 'pipeline$' >> /tmp/pipelinejobs.$$.txt
fi

ip=`hostname`
#ip=${ip:6}
#ip=`echo $ip | sed -e 's/-/./g'` 

#Launch non pipeline jobs first
while read line 
do  
    curl `echo "http://$ip:8888/job/$line/build" | sed -e 's/ /\%20/g'`
done < /tmp/pipelinejobs.$$.txt

