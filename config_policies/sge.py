# Just pull everything from policy
from igs.config_manage.policy import *

dirExists('${sge.queues.harvesting_dir}')
dirOwner('${sge.queues.harvesting_dir}', '${sge.exec_user}', '${sge.exec_user}')

dirExists('${sge.queues.staging_dir}')
dirOwner('${sge.queues.staging_dir}', '${sge.exec_user}', '${sge.exec_user}')

dirExists('${sge.queues.wfworking_dir}')
dirOwner('${sge.queues.wfworking_dir}', '${sge.exec_user}', '${sge.exec_user}')

dirExists('${misc.scratch_dir}')

dirExists('/mnt/projects')
run('tar -C /mnt/projects -xvzf /opt/project_clovr.tgz')

