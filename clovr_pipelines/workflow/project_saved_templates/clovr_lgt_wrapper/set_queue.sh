#!/bin/bash

ssh -oNoneSwitch=yes -oNoneEnabled=yes -o PasswordAuthentication=no -o ConnectTimeout=30 -o StrictHostKeyChecking=no -o ServerAliveInterval=30 -o UserKnownHostsFile=/dev/null -q -i /mnt/keys/devel1.pem root@$1 "echo echo \\\\\\\$SGE_ROOT/bin/\\\\\\\$ARCH/qconf -rattr queue slots 1 \\\\\\\$execq@\\\\\\\$myhostname  \>\> /opt/vappio-scripts/start_exec.sh >> /opt/vappio-scripts/cli/exec_user-data.tmpl"
