#!/bin/bash

hadoop jar /usr/lib/hadoop/hadoop-0.20.2+320-examples.jar pi 10 10000000

if [ "$?" -eq 0 ]; then
    echo "Hadoop pi test completed succcessfully"
else    
    echo "Hadoop pi example encountered an error (error code: $hadoop_ret_val)"
    exit 1
fi    
