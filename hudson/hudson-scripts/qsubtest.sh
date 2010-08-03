#!/bin/bash
set -e
source /opt/vappio-scripts/clovrEnv.sh

qstat

qsub -o /mnt/scratch -e /mnt/scratch -S /bin/sh -b y -sync y -q exec.q sleep 0