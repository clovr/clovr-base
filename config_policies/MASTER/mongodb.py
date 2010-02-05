##
import os
# Just pull everything from policy
from igs.config_manage.policy import *


dirExists('/opt/db/mongo')
##
# For some reason 'run' does not handle this properly so I'm just using os.system for now
os.system('mongod --dbpath=/opt/db/mongo --logpath=/var/log/mongodb.log --fork')
