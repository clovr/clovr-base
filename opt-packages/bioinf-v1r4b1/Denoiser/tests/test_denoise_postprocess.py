#!/usr/bin/env python
"""tests for denoiser functions
"""
from os import remove, rmdir
from cogent.util.unit_test import TestCase, main
from shutil import rmtree
#import as _main to not interfere with TestCase.main
from Denoiser.denoise_postprocess import sort_ids
from Denoiser.settings import PROJECT_HOME

class DenoiserTests(TestCase):

    def setUp(self):
        pass

    def tearDown(self):
        """remove tmp files"""        
        pass

    
    def test_sort_ids(self):
        """sort_ids sorts by abundance"""

        mapping = {"1":["0","2","5","6"],
                   "3":[],
                   "4":[],
                   "11":[1,2,3,4,5,6,7,8,9],
                   "8":["7"]}

        self.assertEqual(sort_ids(["1","3","4","8","11"], mapping), ["11","1","8","4","3"])

if __name__ == "__main__":
    main()
