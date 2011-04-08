#!/usr/bin/env perl

use strict;
use warnings;
use Carp;

use POSIX;
use List::Util qw (shuffle);

use CdbTools;

my $usage = "usage: $0 FakeChimeras.dat\n\n";

my $fakeChimeras = $ARGV[0] or die $usage;

my %div_to_entries;

my $max_per_div = 100;

open (my $fh, $fakeChimeras) or die $!;
while (<$fh>) {
	if (/^\#/) { next; }
	chomp;
	my $line = $_;
	
	my @x = split (/\t/);
	
	my $acc = $x[9];
	if ($acc =~ /chmraD(\d+)/) {
		my $div = $1;
		unless ($div <= 25 && $div >= 1) { next; }
		
		push (@{$div_to_entries{$div}}, $line);
	}
	else {
		die "Error, cannot parse div from $acc\n";
	}
}

foreach my $div (sort {$a<=>$b} keys %div_to_entries) {
	
	my @entries = @{$div_to_entries{$div}};
	
	@entries = shuffle(@entries);
	
	if (scalar(@entries) > $max_per_div) {
		@entries = @entries[0..$max_per_div-1];
	}		
	foreach my $entry (@entries) {
		print "$entry\n";
	}
}
		



