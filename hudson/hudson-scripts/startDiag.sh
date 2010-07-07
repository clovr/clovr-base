#! /bin/bash

source /opt/vappio-scripts/clovrEnv.sh

ec2-describe-instances

if [ "$?" != "0" ] ; then
echo "EC2 isn't working"
exit 1
fi

startDate=`date +"%s"`

startCluster.py --name=ec2_test --num=0 --ctype=diag -b
success=$?

endDate=`date +"%s"`
finalDate=$((endDate-startDate))

terminateCluster.py --name=diagTest

echo "Time elapsed: $finalDate seconds"

exit $success