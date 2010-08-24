#!/bin/bash
set -e
inFile=$1


exec 0<$inFile

while read line
do
    set -- $line
    
    User=`stat --format=%U $1`
    Permission=`stat --format=%A $1`
    if [ "$User" == "$2" ]; then 
	echo "match"
    else
	echo "error $line $User"
	exit 1
    fi
    if [ "$Permission" == "$3" ]; then
        echo "match"
    else
	echo "error $line $Permission"
	exit 1
    fi
done
