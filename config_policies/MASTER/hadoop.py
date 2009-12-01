##
# What the MASTER node needs to do for hadoop
# This assumes that hadoop config files have already been created and now it is just
# a matter of running the right programs
# It assumes it is in ${opt.base_dir}/hadoop

# Just pull everything from policy
from igs.config_manage.policy import *

PKG_DIR = '${opt.base_dir}/hadoop'

run(PKG_DIR + '/bin/hadoop namenode -format')
run(PKG_DIR + '/bin/hadoop_daemon.sh start namenode')
run(PKG_DIR + '/bin/hadoop_daemon.sh start jobtracker')
