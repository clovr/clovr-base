#!/usr/bin/env python 

"""Some utility function for operating on a cluster or MP machine."""

__author__ = "Jens Reeder"
__copyright__ = "Copyright 2010, Jens Reeder, Rob Knight"
__credits__ = ["Jens Reeder", "Rob Knight"]
__license__ = "GPL"
__Version__ = "0.8"
__maintainer__ = "Jens Reeder"
__email__ = "jens.reeder@gmail.com"
__status__ = "Pre-release"

from os import remove, system
from string import join, lowercase
from os.path import exists
from time import sleep
from random import sample

from cogent.app.util import ApplicationNotFoundError

from Denoiser.settings import *



def submit_jobs(commands, prefix):
    """submit jobs using CLUSTER_JOBS_SCRIPTS."""

    if not CLUSTER_JOBS_SCRIPT or not exists(CLUSTER_JOBS_SCRIPT):
        raise ApplicationNotFoundError,"CLUSTER_JOBS_SCRIPT in setting.py not set!"
    fh = open(prefix+"_commands.txt","w") 
    fh.write("\n".join(commands))
    fh.close()
    system('%s -ms %s %s'%(CLUSTER_JOBS_SCRIPT, prefix+"_commands.txt", prefix))
    remove(prefix+"_commands.txt")
    
def setup_workers(num_cpus, outdir, queue=None, verbose=True):
    """Start workers waiting for data."""

    workers = []
    cmds = [] 
    tmpname =  "".join(sample(list(lowercase),8)) #id for cluster job

    for i in range(num_cpus):
        name = outdir+("/%sworker%d" % (tmpname, i))
        workers.append(name)
        cmd  = "%s %s -f %s" % (PYTHON_BIN, DENOISE_WORKER, name)
        if verbose:
            cmd += " -v"
        cmds.append(cmd)

    submit_jobs(cmds, tmpname)
    #wait a bit more for all workers to come alive
    for worker in workers:
        while(not exists(worker+".alive")):
            sleep(1)

    return workers

def adjust_workers(num_flows, num_cpus, workers, log_fh=None):
    """Stop workers no longer needed."""
    if(num_flows < (num_cpus-1)*MIN_PER_CORE):       
        if log_fh:
            log_fh.write("Adjusting number of workers:\n")
            log_fh.write("flows: %d   cpus:%d\n" % (num_flows, num_cpus))
        # TODO: make sure this works with future division
        per_core = max(MIN_PER_CORE, (num_flows/num_cpus)+1)
        for i in range (num_cpus):
            if(i*per_core > num_flows):
                worker = workers.pop()
                remove(worker+".alive")
                num_cpus = num_cpus-1
                if log_fh:
                    log_fh.write("released worker %s\n"% worker)

        assert(num_cpus==len(workers))                 
        if log_fh:
            log_fh.write("New number of cpus:%d\n"% num_cpus)
    
    return num_cpus

def stop_workers(workers, log_fh=None):
    """Stop all worker proccesses."""
    for worker in workers:
        try:
            remove(worker+".alive")
        except OSError:
            if log_fh:
                log_fh.write("Worker %s seems to be dead already. Check for runaways!\n"% worker)

def check_workers(workers, log_fh=None):
    """Check if all workers are still alive. Exit otherwise"""
    for worker in workers:
        if not exists(worker+".alive"):
            if log_fh:
                log_fh.write("FATAL ERROR\nWorker %s not alive. Aborting\n" % worker)
            stop_workers(workers, log_fh)
            exit()
