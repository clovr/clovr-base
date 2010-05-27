#!/usr/bin/env python

"""test the global settings
"""

from os import access, X_OK, R_OK
from os.path import exists
from subprocess import Popen, PIPE, STDOUT
from cogent.util.unit_test import TestCase, main
from Denoiser.settings import *

class DenoiserTests(TestCase):

    def test_project_home(self):
        """PROJECT_HOME is set to a good value"""
        if (not PROJECT_HOME):
            self.fail("PROJECT_HOME must be set in settings.py")
            
        self.assertTrue(exists(PROJECT_HOME), "PROJECT_HOME is not set to a valid path: %s" %PROJECT_HOME)

        self.assertTrue(exists(PROJECT_HOME+"/Denoiser/__init__.py"),
                        "PROJECT_HOME does not point to the right directory")

    def test_cluster_jobs_script(self):
        """CLUSTER_JOBS_SCRIPT is set to a good value"""
        if (CLUSTER_JOBS_SCRIPT):
            self.assertTrue(exists(CLUSTER_JOBS_SCRIPT),
                            "CLUSTER_JOBS_SCRIPT is not set to a valid path: %s" % CLUSTER_JOBS_SCRIPT)
            #check if executable
            self.assertTrue(access(CLUSTER_JOBS_SCRIPT, X_OK),
                            "CLUSTER_JOBS_SCRIPT is not executable: %s" % CLUSTER_JOBS_SCRIPT)
        else:
            #Can't run in parallel, but not a critical error
            pass
        
    def test_denoise_worker(self):
        """DENOISE_WORKER is set correct and is callable."""

        self.assertTrue(exists(DENOISE_WORKER),
                            "DENOISER_WORKER is not set to a valid path: %s" % DENOISE_WORKER)
                       
        #test if its callable
        command = "%s -h"% DENOISE_WORKER
        proc = Popen(command,shell=True,universal_newlines=True,\
                       stdout=PIPE,stderr=STDOUT)

        if (proc.wait() !=0):
            self.fail("Calling %s failed. Check permissions and that it is in fact an executable." % DENOISE_WORKER)

        result = proc.stdout.read()     
        #check that the help string looks correct
        self.assertTrue(result.startswith("Usage"))


if __name__ == "__main__":
    main()
