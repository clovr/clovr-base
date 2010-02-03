##
# Just pull everything from policy
from igs.config_manage.policy import *

fileExists('${opt.base_dir}/hadoop/conf/core-site.xml.tmpl')
fileExists('${opt.base_dir}/hadoop/conf/hdfs-site.xml.tmpl')
fileExists('${opt.base_dir}/hadoop/conf/mapred-site.xml.tmpl')

executeTemplate('${opt.base_dir}/hadoop/conf/core-site.xml.tmpl')
executeTemplate('${opt.base_dir}/hadoop/conf/hdfs-site.xml.tmpl')
executeTemplate('${opt.base_dir}/hadoop/conf/mapred-site.xml.tmpl')
