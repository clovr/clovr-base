#!/usr/bin/perl

$hostname = `hostname -f`;
chomp $hostname;
if ( $hostname eq "") 
{
    exit 1; 
}
$ping = `ping -c 1 $hostname`;
#print "$ping\n";

$homepage=`lwp-request  $hostname`;
if ( $? !=  0 )
{
    print "IT DONT WORK\n";
    exit 1;
}
$ganglia= `lwp-request  '$hostname/ganglia/'`;
$ergatis= `lwp-request  '$hostname/ergatis/'`;


if ( $homepage =~ /error/ || $ganglia =~ /error/ || $ergatis =~ /error/)
{
    print "IT DONT WORK\n";
    exit 1;
}
