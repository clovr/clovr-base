#!/usr/bin/env perl

use strict;
use warnings;

my %data_vals;


my $counter = 0;
while (<>) {
	
	if (/error/) { next; }
	
	my @x = split(/\t/);
	my $div = int($x[3]);
	my $stdev_info = $x[4];
	my ($trash, $stdev) = split(/\s+/, $stdev_info);
	
	if ($div > 30 || $div < 1) { next; }
	
	push (@{$data_vals{$div}}, $stdev);

	$counter++;
	#if ($counter > 10000) { last; }

}

my @pts = (0.5, 0.75, 0.9, 0.95, 0.99, 0.999, 0.9999);

print "Div\tNumDataPts\t" . join("\t", @pts) . "\n";

foreach my $div (sort {$a<=>$b} keys %data_vals) {

	my @vals = sort {$a<=>$b} @{$data_vals{$div}};

	my $num_pos = $#vals;

	print "$div\t" . ($num_pos+1) . "\t";
	
	foreach my $pt (@pts) {
		my $index = int($pt * $num_pos);
		my $val = $vals[$index];
		print "\t$val";
	}
	print "\n";

}

exit(0);


		
