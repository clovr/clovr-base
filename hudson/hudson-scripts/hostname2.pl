#!/usr/bin/perl

$hostname = `hostname -f`;
chomp $hostname;
if ( $hostname eq "") 
{
    exit 1; 
}

$ergatis= `lwp-request  '$hostname/ergatis/'`;
