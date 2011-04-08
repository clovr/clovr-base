#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 RDP_classifier.output\n\n";

my $file = $ARGV[0] or die $usage;


open (my $fh, $file) or die "Error, cannot open file $file";
while (<$fh>) {
	chomp;
	if (/^>(\S+)/) {
		my $acc = $1;
		my $taxonomy = <$fh>;
		$taxonomy =~ s/\s+$//;
		$taxonomy =~ s/;$//;

		print "$acc\t$taxonomy\n";
	}
}

close $fh;

exit(0);

