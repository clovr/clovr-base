#!/usr/bin/perl

$hostname = `hostname -f`;
chomp $hostname;
if ( $hostname eq "") 
{
    exit 1; 
}

$ganglia= `lwp-request  '$hostname/ganglia/'`;
