#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

ec2-describe-instances

if [ "$?" != "0" ] ; then
echo "EC2 isn't working"
exit 1
fi

cp /opt/vappio-conf/clovr.conf /opt/vappio-conf/temp.conf
sed -e "s/master_type=m1.large/master_type=m1.xlarge/g" /opt/vappio-conf/temp.conf

startDate=`date +"%s"`

startCluster.py --conf-name=temp.conf --name=ec2_test --num=0 --ctype=ec2 -b
success=$?

endDate=`date +"%s"`
finalDate=$((endDate-startDate))

terminateCluster.py --name=ec2_test

echo "Time elapsed: $finalDate seconds"
rm /opt/vappio-conf/temp.conf

exit $success