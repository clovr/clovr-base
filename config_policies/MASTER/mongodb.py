##
# Just pull everything from policy
from igs.config_manage.policy import *


dirExists('/opt/db/mongo')
run('mongod --dbpath=/opt/db/mongo --logpath=/var/log/mongodb.log --fork &')
