#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use Fasta_reader;


my $fasta_reader = new Fasta_reader("$FindBin::Bin/eco.prokMSA");
my $seq_obj = $fasta_reader->next();
my $sequence = $seq_obj->get_sequence();

my @chars = split (//, $sequence);

my $counter = 0;
while (<>) {
	chomp;
	my ($index, $val) = split (/\t/);
	if ($chars[$index] =~ /\w/) {
		print $counter++ . "\t$val\n";
	}
}

exit(0);


