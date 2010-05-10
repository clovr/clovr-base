#!/usr/bin/env python

"""Tests for submitting jobs via qsub."""

from os import remove, environ
from os.path import exists
from time import sleep

from cogent.util.unit_test import TestCase, main
from cogent.app.util import get_tmp_filename


from Denoiser.make_cluster_jobs import QSUB_TEXT, make_jobs, submit_jobs,\
                                       main as _main

class Test_make_cluster_jobs(TestCase):

    def setUp(self):
        
        self.home = environ['HOME']
        self.queue = "friendlyq"
        #make a somewhat random test file    
        self.tmp_result_file =  "%s/test_hello_8827366253.txt" % self.home 
        self.command = "echo hello > %s\n" % self.tmp_result_file
        self.tmp_name = get_tmp_filename(tmp_dir="/tmp",
                                         prefix="make_cluster_jobs_test_",
                                         suffix = ".txt")
        fh = open(self.tmp_name,"w")
        fh.write(self.command)
        fh.close()

    def tearDown(self):
        remove(self.tmp_name)
        if exists(self.tmp_result_file):
            remove(self.tmp_result_file)
            
    def test_make_jobs(self):
     
        #no commands should make no jobs files
        self.assertEqual(make_jobs([], "test", self.queue), [])
     
        #one job file should be created
        filenames = make_jobs([self.command], "test_qsub", self.queue)   
        self.assertTrue(len(filenames)==1)
        observed_text= list(open(filenames[0]))

        self.assertEqual("".join(observed_text),
                         QSUB_TEXT % ("72:00:00", 1, 1, self.queue,
                                      "test_qsub", "oe",
                                      self.command))

    def test_submit_jobs(self):
        """submit jobs via qsub works."""
        
        filenames = make_jobs([self.command], "test_qsub", self.queue) 
        submit_jobs(filenames)
        
        for i in range(10):
            if exists(self.tmp_result_file):
                return
            else:
                #wait for job to finish
                sleep(10)
        self.fail("The test job apparently never finished.\n"
                  +"check the jobs error log and check the queue status\n.")
              
    def test_main(self):
        """the command line interface works as expected"""

        args = ["-ms", self.tmp_name, "testmain"]
        _main(args)
        
        for i in range(10):
            if exists(self.tmp_result_file):
                return
            else:
                #wait for job to finish
                sleep(10)
        self.fail("The test job apparently never finished.\n"
                  +"check the jobs error log and check the queue status\n.")

if __name__ == "__main__":
    main()
