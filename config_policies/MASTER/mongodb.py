##
import os
# Just pull everything from policy
from igs.config_manage.policy import *

def startup():
    dirExists('/opt/db/mongo')
    run('mongod --dbpath=/opt/db/mongo --logpath=/var/log/mongodb.log --fork > /dev/null 2>&1')

def shutdown():
    run('killall mongod')
    

