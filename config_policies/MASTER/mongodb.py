import time
##
# Just pull everything from policy
from igs.config_manage.policy import *

##
# We are going to add the 'local' cluster to Mongo on start up
# It might be possible that this should be moved to another script
# but this will do for right now
from igs.utils.config import configFromStream

from vappio.cluster.persis_mongo import dump
from vappio.cluster.control import Cluster

##
# this is temporary, going to need to replace this with some sort of 'local' implementation
# even if it is just a dummy implemetnation
from vappio import ec2



def startup():
    dirExists('/opt/db/mongo')
    run('mongod --dbpath=/opt/db/mongo --logpath=/var/log/mongodb.log --fork > /dev/null 2>&1')
    ##
    # let mongo come up
    time.sleep(1)
    cluster = Cluster('local', ec2.control, configFromStream(open('/tmp/machine.conf')))
    cluster.setMaster(ec2.control.Instance(instanceId='local',
                                           amiId=None,
                                           pubDns=cluster.config('MASTER_IP'),
                                           privDns=cluster.config('MASTER_IP'),
                                           state='running',
                                           key=None,
                                           index=None,
                                           instanceType=None,
                                           launch=None,
                                           availabilityZone=None,
                                           monitor=None))
    dump(cluster)
                                           
    
def shutdown():
    run('killall mongod')
    

