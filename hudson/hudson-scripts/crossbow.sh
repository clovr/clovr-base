#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

# Create necessary directories on the hdfs and place our test data there
hadoop dfs -mkdir /hudson/crossbow-refs
hadoop dfs -put /opt/hudson/crossbow/e_coli.jar /hudson/crossbow-refs

hadoop dfs -mkdir /hudson/crossbow/example/e_coli
hadoop dfs -put /opt/hudson/crossbow/small.manifest /hudson/crossbow/example/e_coli/small.manifest

# Run Crossbow
$CROSSBOW_HOME/cb_hadoop --preprocess \
                         --input=hdfs:///hudson/crossbow/example/e_coli/small.manifest \
                         --output=hdfs:///hudson/crossbow/example/e_coli/output_small \
                         --reference=hdfs:///hudson/crossbow-refs/e_coli.jar \
                         --all-haploids

# Clean up on the hdfs afterwords
hadoop dfs -rmr /hudson/crossbow-refs
hadoop dfs -rmr /hudson/crossbow




