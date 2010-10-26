#!/usr/bin/perl -w

print "$ARGV[0]\n";
foreach $i (1..$ARGV[0]) {

$FH="FH${i}";

open ($FH,'>',"/tmp/Test${i}.$$.log") || die "$!";

print $FH "$i\n";

} 
