import os
import time

from twisted.python import reflect

##
# Just pull everything from policy
from igs.config_manage.policy import *

##
# We are going to add the 'local' cluster to Mongo on start up
# It might be possible that this should be moved to another script
# but this will do for right now
from igs.utils.config import configFromStream, configFromEnv
from igs.utils.functional import tryUntil

from vappio.cluster import control as cluster_ctl

from vappio.credentials import manager


def tryDump(cluster):
    def _():
        try:
            cluster_ctl.saveCluster(cluster)
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

    if os.path.exists('/tmp/cred-info'):
        cert, pkey, ctype, metadata = open('/tmp/cred-info').read().split('\t')
        manager.saveCredential(manager.createCredential('local',
                                                        'Local credential',
                                                        reflect.namedAny('vappio.' + ctype + '.control'),
                                                        open(cert).read(),
                                                        open(pkey).read(),
                                                        True,
                                                        metadata and dict([v.split('=', 1) for v in metadata.split(',')]) or {}))
    else:
        manager.saveCredential(manager.createCredential('local',
                                                        'Dummy local credential',
                                                        reflect.namedAny('vappio.local.control'),
                                                        None,
                                                        None,
                                                        True,
                                                        None))
    credential = manager.loadCredential('local')
    options = configFromStream(open('/tmp/machine.conf'), configFromEnv())
    options = configFromMap(
            {'cluster': {'master_groups': [f.strip() for f in options('cluster.master_groups').split(',')],
                         'exec_groups': [f.strip() for f in options('cluster.exec_groups').split(',')],
                         }
             }, options)
    cluster = cluster_ctl.Cluster('local', credential, options)
    cluster = cluster.setMaster(credential.ctype.Instance(instanceId='local',
                                                          amiId=None,
                                                          pubDns=cluster.config('MASTER_IP'),
                                                          privDns=cluster.config('MASTER_IP'),
                                                          state=credential.ctype.Instance.RUNNING,
                                                          key=None,
                                                          index=None,
                                                          instanceType=None,
                                                          launch=None,
                                                          availabilityZone=None,
                                                          monitor=None,
                                                          spotRequestId=None,
                                                          bidPrice=None))


    ##
    # Try to save the cluster a bunch of times, waitign 2 seconds between
    # attempts
    tryUntil(5, lambda : time.sleep(2), tryDump(cluster))

    ##
    # a hack right now but delete cert and key file if they exist since ROOT made them
    # nobody else will be able to write them later on
    if hasattr(cluster.credInst, 'cert') and cluster.credInst.cert:
        os.remove(cluster.credInst.cert)
    if hasattr(cluster.credInst, 'pkey') and cluster.credInst.pkey:
        os.remove(cluster.credInst.pkey)

    
def shutdown():
    run('killall mongod')
    

