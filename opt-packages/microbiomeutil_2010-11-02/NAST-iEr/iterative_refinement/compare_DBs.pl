#!/usr/bin/env perl

use strict;
use warnings;

use lib ($ENV{EUK_MODULES});
use Fasta_reader;
use CdbTools;

my $usage = "usage: dbFrom dbTo\n\n";

my $dbFrom = $ARGV[0] or die $usage;
my $dbTo = $ARGV[1] or die $usage;


my $fasta_reader = new Fasta_reader($dbFrom);

while (my $seq_obj = $fasta_reader->next()) {
	
	my $acc = $seq_obj->get_accession();
	
	my $sequence = uc $seq_obj->get_sequence();
	$sequence =~ s/\./-/g;
	
	my $other_seq = uc &cdbyank_linear($acc, $dbTo);
	$other_seq =~ s/\./-/g;

	if ($sequence eq $other_seq) {
		print "$acc\tSAME\n";
	}
	else {
		print "$acc\tDIFFERENT\n";
	}
}


exit(0);


