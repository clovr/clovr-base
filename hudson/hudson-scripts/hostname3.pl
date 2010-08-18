#!/usr/bin/perl

$hostname = `hostname -f`;
chomp $hostname;
if ( $hostname eq "") 
{
    exit 1; 
}

$ganglia= `lwp-request  '$hostname/ganglia/'`;

if ( $ganglia =~ /error/ )
{
    print "IT DONT WORK\n";
    exit 1;
}
