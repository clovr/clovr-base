#!/bin/bash
set +e
source /opt/vappio-scripts/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`

## IN ORDER TO RUN THIS TEST A CERT AND PKEY FILE MUST BE AVAILABLE IN /mnt/keys
cert=`ls /mnt/keys/cert*`
pkey=`ls /mnt/keys/pk*`

# Add a credential for our test cluster
vp-add-credential --cred-name=hadoop_EC2_${DATE} \
                  --ctype=ec2 \
                  --pkey=${pkey} \
                  --cert=${cert}

# Now copy our clovr conf file and make a temporary conf file to disbale exec node spot prices
cp -f /mnt/vappio-conf/clovr.conf /mnt/vappio-conf/hadoop_EC2.conf
sed -i -e "s/exec_bid_price=0.68/#exec_bid_price=0.68/" /mnt/vappio-conf/hadoop_EC2.conf                  

# Start an EC2 cluster with two nodes to run our hadoop test on
vp-start-cluster --conf-name=hadoop_EC2.conf \
                 --name=hadoop_EC2_${DATE} \
                 --num=2 \
                 --cred=hadoop_EC2_${DATE} 

# Once our cluster is up we can start the hadoop pi test using the runCommandOnCluster script
runCommandOnCluster.py --just_master \
                       --name=hadoop_EC2_${DATE} \
                       --cmd="hadoop jar /opt/hadoop/hadoop-*-examples.jar pi 10 10000000"
hadoop_ret_val=$?

# Clean up by terminating our cluster and deleting our temp cluster
vp-terminate-cluster --force \
                     --name=hadoop_EC2_${DATE}

rm -f /mnt/vappio-conf/hadoop_EC2.conf                     
                       
exit $hadoop_ret_val
