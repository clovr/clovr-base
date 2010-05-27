#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 breakpoint.output [CM|CS]\n\n";

my $breakpoint_file = $ARGV[0] or die $usage;
my $CM_or_CS = $ARGV[1] or die $usage;

unless ($CM_or_CS =~ /^(CM|CS)$/) { 
	
	die $usage;
}

my $index = ($CM_or_CS eq 'CS') ? 3:4;

my @pos_counter;
$#pos_counter = 1600; # set to presumed max xrange

open (my $fh, $breakpoint_file) or die $usage;
while (<$fh>) {
	chomp;
	my @x = split(/\t/);
	$pos_counter[ $x[$index] ]++;
}
close $fh;

for (my $i = 0; $i <= $#pos_counter; $i++) {
	
	my $val = $pos_counter[$i] || 0;

	print "$i\t$val\n";
}

exit(0);


