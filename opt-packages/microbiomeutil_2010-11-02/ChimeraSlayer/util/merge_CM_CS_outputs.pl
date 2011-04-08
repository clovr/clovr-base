#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 CM.CS.parsed(file)  .CM(file)\n\n\n";

my $CMCS_parsed = $ARGV[0] or die $usage;
my $CM_file = $ARGV[1] or die $usage;


my %CS;
{
	open (my $fh, "$CMCS_parsed") or die $!;
	while (<$fh>) {
		chomp;
		my ($acc, $rest) = split (/\t/, $_, 2);
		
		$CS{$acc} = $rest;
		
	}
	close $fh;
}

open (my $fh, $CM_file) or die $!;
while (<$fh>) {
	chomp;
	if (/^ChimeraMaligner/) {
		my ($token, $acc, $flag, $perID, $ranges) = split (/\t/, $_, 5);
		$ranges =~ s/\t/ /g;

		my $CS_text = $CS{$acc} or die "Error, no CS text for $acc ";
		
		print "$token\t$acc\t$flag\t$perID\t$ranges\t$CS_text\n";

	}
}
close $fh;

exit(0);


