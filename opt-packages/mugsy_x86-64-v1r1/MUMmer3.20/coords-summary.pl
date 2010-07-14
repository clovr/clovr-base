#!/usr/bin/perl

#Must process delta with delta-filter -1
#then run show-coords 

use strict;

my $refsum=0;
my $qrysum=0;

while(my $line=<STDIN>){
    $line =~ s/^\s+//g;
    my @x = split(/\s+/,$line);
    $refsum += $x[6];
    $qrysum += $x[7];
}

print "Total ref len:$refsum\n";
print "Total qry len:$qrysum\n";
