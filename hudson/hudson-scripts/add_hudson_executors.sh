#!/bin/bash

export NUM_EXECS=2
perl -pi -e 's/\<numExecutors\>\d+\<\/numExecutors\>/<numExecutors\>$ENV{NUM_EXECS}<\/numExecutors>/' /var/lib/hudson/config.xml
curl -d "json=%7B%7D&Submit=Yes" "http://localhost:8888/restart"

exit $?
