#!/usr/bin/env python
##
import json
import os
import cgi

fdata = open('/etc/pure-ftpd/ftp_passwd').readline().strip()

print "Content-Type: application/json"
print 

pass_dict = dict(success=True, data=[dict(password=fdata)])
print json.dumps(pass_dict)

