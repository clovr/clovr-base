#!/bin/bash 

set -e
source /root/clovrEnv.sh

DATE=`date +"%m-%d-%Y-%T"`
QIIME_OUTFILE=/tmp/qiime_unit_test_${DATE}.out

# Run Qiime all_tests.py script and capture stdout to a temp file so we can pull out the number
# of failed tests
python /opt/hudson/qiime/all_tests.py | tee $QIIME_OUTFILE

# Check to see how many of our tests failed
QIIME_FAILED=`cat $QIIME_OUTFILE | perl -ne 'if ($_ =~ /FAILED \(errors=(\d+)\)/) { print $1; }'`

# Cleanup temp file
rm -f $QIIME_OUTFILE

if [ $QIIME_FAILED > 0 ]; then
    echo "Qiime unit tests failed"
    exit 1
else
    echo "Qiime unit tests passed"
fi
