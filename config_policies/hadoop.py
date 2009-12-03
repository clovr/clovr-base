##
# Ensure hadoop exists and is installed

# Just pull everything from policy
from igs.config_manage.policy import *

PKG_NAME = 'hadoop-0.20.1'
PKG_DIR = '${opt.package_dir}/' + PKG_NAME

ensureOptPkg(PKG_NAME)
fileExists(PKG_DIR + '/conf/core-site.xml.tmpl')
fileExists(PKG_DIR + '/conf/hdfs-site.xml.tmpl')
fileExists(PKG_DIR + '/conf/mapred-site.xml.tmpl')

executeTemplate(PKG_DIR + '/conf/core-site.xml.tmpl')
executeTemplate(PKG_DIR + '/conf/hdfs-site.xml.tmpl')
executeTemplate(PKG_DIR + '/conf/mapred-site.xml.tmpl')

installOptPkg(PKG_NAME)
