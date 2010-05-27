#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use lib ("$FindBin::Bin/../PerlLib");

use Fasta_reader;

my $usage = "usage: $0 mFastaFile\n\n";

my $mFasta = $ARGV[0] or die $usage;

main: {
	
	my $fasta_reader = new Fasta_reader($mFasta);
	
	while (my $seq_obj = $fasta_reader->next()) {
		
		my $header = $seq_obj->get_header();

		my $sequence = $seq_obj->get_sequence();

		$sequence =~ s/[\-\.]//g;

		$sequence =~ s/(\S{60})/$1\n/g;

		print ">$header\n$sequence\n";
	}
	
	exit(0);
}

