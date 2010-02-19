# Just pull everything from policy
from igs.config_manage.policy import *

import sys

def startup():
    # Turning this config off for now
    return

    run("""echo ${MASTER_IP} > ${sge.root}/${sge.cell}/common/act_qmaster""")
    run('rm -rf /var/spool/sge')
    dirExists('/var/spool/sge')
    dirOwner('/var/spool/sge', '${sge.admin_user}', '${sge.admin_user}')
    
    run("""curl --retry 5 --silent --show-error --fail "http://${MASTER_IP}:8080/add_host.cgi?host=`${MY_IP}`" """)
    
    run('${sge.root}/${sge.cell}/common/sgeexecd')
    
    run('${sge.root}/bin/${sge.arch}/qconf -as ${MY_IP}')
    
    run('${sge.root}/bin/${sge.arch}/qsub -o ${misc.scratch} -e ${misc.scratch} -b y -sync y -q ${sge.queues.stagingq},${sge.queues.stagingsubq} ${sge.seeding_script} ${MY_IP} ${sge.queues.stagingsubq}')
    
    run('${sge.root}/bin/${sge.arch}/qconf -aattr queue hostlist ${MY_IP} ${sge.queues.execq}')

def shutdown():
    pass
