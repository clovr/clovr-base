##
# What the MASTER node needs to do for hadoop
# This assumes that hadoop config files have already been created and now it is just
# a matter of running the right programs
# It assumes it is in ${opt.base_dir}/hadoop
import time

# Just pull everything from policy
from igs.config_manage.policy import *

PKG_DIR = '${opt.base_dir}/hadoop'

def startup():
    ##
    # We do not want to format it if it's already been created
    run('yes N | ' + PKG_DIR + '/bin/hadoop namenode -format', ignoreError=True)
    run(PKG_DIR + '/bin/hadoop-daemon.sh start namenode')
    time.sleep(5)
    run(PKG_DIR + '/bin/hadoop-daemon.sh start jobtracker')
    run(PKG_DIR + '/bin/hadoop-daemon.sh start datanode')
    run(PKG_DIR + '/bin/hadoop-daemon.sh start tasktracker')

def shutdown():
    run(PKG_DIR + '/bin/hadoop-daemon.sh stop jobtracker')    
    run(PKG_DIR + '/bin/hadoop-daemon.sh stop datanode')
    run(PKG_DIR + '/bin/hadoop-daemon.sh stop tasktracker')
    run(PKG_DIR + '/bin/hadoop-daemon.sh stop namenode')

