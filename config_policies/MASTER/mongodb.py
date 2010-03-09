import time
##
# Just pull everything from policy
from igs.config_manage.policy import *

##
# We are going to add the 'local' cluster to Mongo on start up
# It might be possible that this should be moved to another script
# but this will do for right now
from igs.utils.config import configFromStream, configFromEnv
from igs.utils.functional import tryUntil

from vappio.cluster.persist_mongo import dump
from vappio.cluster.control import Cluster

##
# this is temporary, going to need to replace this with some sort of 'local' implementation
# even if it is just a dummy implemetnation
from vappio.ec2 import control as ec2control

def tryDump(cluster):
    def _():
        try:
            dump(cluster)
            return True
        except:
            return False

    return _

def startup():
    dirExists('/opt/db/mongo')
    run('mongod --dbpath=/opt/db/mongo --logpath=/var/log/mongodb.log --fork > /dev/null 2>&1')
    ##
    # let mongo come up
    time.sleep(3)
    options = configFromStream(open('/tmp/machine.conf'), configFromEnv())
    options = configFromMap(
            {'cluster': {'master_groups': [f.strip() for f in options('cluster.master_groups').split(',')],
                         'exec_groups': [f.strip() for f in options('cluster.exec_groups').split(',')],
                         }
             }, options)
    cluster = Cluster('local', ec2control, options)
    cluster.setMaster(ec2control.Instance(instanceId='local',
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


    ##
    # Try to save the cluster a bunch of times, waitign 2 seconds between
    # attempts
    tryUntil(5, lambda : time.sleep(2), tryDump(cluster))

    
def shutdown():
    run('killall mongod')
    

