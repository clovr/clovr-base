#!/usr/bin/env python
"""Run all tests.
"""

##Adapted from cogent.test.all_tests.py

from os import walk, environ
from os.path import join

from subprocess import Popen, PIPE, STDOUT
import re

__author__ = "Jens Reedert"
__copyright__ = "Copyright 2009, the PyCogent Project"
__credits__ = ["Rob Knight, Greg Caporaso"]
__license__ = "GPL"
__version__ = "0.1"
__maintainer__ = "Jens Reeder"
__email__ = "jreeder@gmail.com"
__status__ = "Prototype"

good_pattern = re.compile('OK\s*$') 
application_not_found_pattern = re.compile('ApplicationNotFoundError')
start_dir = '.'
python_name = 'python'

bad_tests = []
filenames = []
missing_app_tests = []

for root, dirs, files in walk(start_dir):
    for name in files:
        if name.startswith('test_') and name.endswith('.py'):
            filenames.append(join(root,name))
filenames.sort()

for filename in filenames:
    print "Testing %s:\n" % filename
    command = '%s %s -v' % (python_name, filename)
    result = Popen(command,shell=True,universal_newlines=True,\
                       stdout=PIPE,stderr=STDOUT).stdout.read()
    print result
    if not good_pattern.search(result):
        if application_not_found_pattern.search(result):
            missing_app_tests.append(filename)
        else:
            bad_tests.append(filename)

if bad_tests:
    print "Failed the following tests:\n%s" % '\n'.join(bad_tests)
elif missing_app_tests:
    print "Failed the following tests due to missing dependencies:\n%s" % '\n'.join(missing_app_tests)
else:
    print "All tests passed successfully."
