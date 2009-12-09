# Just pull everything from policy
from igs.config_manage.policy import *

import sys

# Turning this off for now
sys.exit(0)

run("""hostname -f > ${sge.root}/${sge.cell}/common/act_qmaster""")
run('rm -rf /var/spool/sge')
dirExists('/var/spool/sge')
dirOwner('/var/spool/sge', '${sge.admin_user}', '${sge.admin_user}')

run('${sge.root}/${sge.cell}/common/sgemaster')
run('wipeSGEQueues.py')
run('${sge.root}/${sge.cell}/common/sgeexecd')

# add user to operator list
run('${sge.root}/bin/${sge.arch}/qconf -ao ${sge.exec_user}', ignoreError=True)
# add user to manager list
run('${sge.root}/bin/${sge.arch}/qconf -am ${sge.exec_user}', ignoreError=True)
# add apache user to manager list
run('${sge.root}/bin/${sge.arch}/qconf -am ${sge.apache_user}', ignoreError=True)
# add an administrative host
run('${sge.root}/bin/${sge.arch}/qconf -ah ${MASTER_IP}', ignoreError=True)
# add a submit host
run('${sge.root}/bin/${sge.arch}/qconf -as ${MASTER_IP}', ignoreError=True)
# add project from file
run('${sge.root}/bin/${sge.arch}/qconf -Aprj ${sge.project}', ignoreError=True)
## add a queue from file
run('${sge.root}/bin/${sge.arch}/qconf -Aq ${sge.queues.execq_conf}', ignoreError=True)
run('${sge.root}/bin/${sge.arch}/qconf -Aq ${sge.queues.stagingq_conf}', ignoreError=True)
run('${sge.root}/bin/${sge.arch}/qconf -Aq ${sge.queues.stagingsubq_conf}', ignoreError=True)
run('${sge.root}/bin/${sge.arch}/qconf -Aq ${sge.queues.wfq_conf}', ignoreError=True)
run('${sge.root}/bin/${sge.arch}/qconf -Aq ${sge.queues.harvestingq_conf}', ignoreError=True)
run('${sge.root}/bin/${sge.arch}/qconf -Aq ${sge.queues.repositoryq_conf}', ignoreError=True)
# add to a list attribute of an object
# -aattr obj_nm attr_nm val obj_id_lst
run('${sge.root}/bin/${sge.arch}/qconf -aattr queue hostlist ${MASTER_IP} ${sge.queues.stagingq}', ignoreError=True)
run('${sge.root}/bin/${sge.arch}/qconf -aattr queue hostlist ${MASTER_IP} ${sge.queues.stagingsubq}', ignoreError=True)
run('${sge.root}/bin/${sge.arch}/qconf -aattr queue hostlist ${MASTER_IP} ${sge.queues.wfq}', ignoreError=True)
run('${sge.root}/bin/${sge.arch}/qconf -aattr queue hostlist ${MASTER_IP} ${sge.queues.repositoryq}', ignoreError=True)
run('${sge.root}/bin/${sge.arch}/qconf -aattr queue hostlist ${MASTER_IP} ${sge.queues.harvestingq}', ignoreError=True)
run('${sge.root}/bin/${sge.arch}/qconf -aattr queue slots ${sge.queues.stagingslots} ${sge.queues.stagingq}', ignoreError=True)
run('${sge.root}/bin/${sge.arch}/qconf -aattr queue slots ${sge.queues.stagingsubslots} ${sge.queues.stagingsubq}', ignoreError=True)
run('${sge.root}/bin/${sge.arch}/qconf -aattr queue slots ${sge.queues.harvestingslots} ${sge.queues.harvestingq}', ignoreError=True)
run('${sge.root}/bin/${sge.arch}/qconf -aattr queue slots ${sge.queues.execslots} ${sge.queues.execq}', ignoreError=True)

