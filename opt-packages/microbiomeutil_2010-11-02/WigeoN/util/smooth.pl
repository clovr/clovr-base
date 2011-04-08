#!/usr/bin/env perl

use strict;
use warnings;

use lib ($ENV{EUK_MODULES});
use BHStats;

my $usage = "usage: $0 pointsFile windowSize\n\n";

my $pointsFile = $ARGV[0] or die $usage;
my $windowSize = $ARGV[1] or die $usage;

main: {

	my @pos;

	open (my $fh, $pointsFile) or die "Error, cannot open file $pointsFile";
	while (<$fh>) {
		chomp;
		my ($position, $val) = split (/\t/);
		
		if ($position > 10000) { die "Error, pos out of range: $position"; } # avoid creating a massive array
		
		$pos[$position] = $val;
	}
	close $fh;


	for (my $i = 1; $i <= $#pos - $windowSize +1; $i++) {
		
		my $midpt = $i + ($windowSize/2);
		
		my @vals = @pos[$i..$i+$windowSize-1];
		
		#print join (" ", @vals) . "\n";

		my $avg = &BHStats::avg(@vals);
		#print "AVG: $avg\n\n";
		
		print "$midpt\t$avg\n";
	}
}


exit(0);

		
