#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

my $usage = "usage: $0 db.NAST\n\n";

my $db = $ARGV[0] or die $usage;

my $prev = "$db";
for my $i (1..25) {
	
	my $nast = "$i.NAST";
	
	my $cmd = "$FindBin::Bin/compare_DBs.pl $prev $nast | grep DIFFERENT | wc -l ";
	
	my $count_diff = `$cmd`;
	chomp $count_diff;
	
	print "$prev vs. $nast:  $count_diff DIFFERENT\n";

	
	$prev = $nast;
	
}

exit(0);
