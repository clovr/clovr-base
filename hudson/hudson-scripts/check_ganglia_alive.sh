#!/bin/bash

hostname=`hostname -f`
lwp-request $hostname/ganglia

