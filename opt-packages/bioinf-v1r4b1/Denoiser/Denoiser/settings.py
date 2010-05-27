#!/usr/bin/env python

"""This file contains some global variables."""

from os import environ

home = environ['HOME']

#see the INSTALL file for more details

PROJECT_HOME     = "/opt/opt-packages/bioinf-v1r4b1/Denoiser/" #This must be set to the install directory

#specify the full path to python here if not in PATH 
PYTHON_BIN       = "python"


#use this one for clusters with qsub based queueing system
CLUSTER_JOBS_SCRIPT= PROJECT_HOME + "Denoiser/make_cluster_jobs.py"
#use this one for multi-core system (adapt PATH_TO_QIIME)
#CLUSTER_JOBS_SCRIPT= PATH_TO_QIIME + "/scripts/start_parallel_jobs.py"

#These don't need to be changed for a regular install
DENOISE_WORKER   = PROJECT_HOME + "/Denoiser/denoise_worker.py" #Worker needed only on cluster

SIGNAL_DIST_FILE = PROJECT_HOME + "/Data/probabilities.txt"
LOOKUP           = PROJECT_HOME + "/Data/LookUp.dat"
FLOWGRAMALI      = PROJECT_HOME + "/bin/FlowgramAli_4frame"

MIN_PER_CORE     = 50 #minimum number of flowgrams to be denoised per core
