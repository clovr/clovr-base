#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

use Fasta_reader;

my $usage = "usage: $0 multiFasta.NAST\n\n";

my $fasta_file = $ARGV[0] or die $usage;


main: {
	
	my %seqs = &parse_seqs($fasta_file);

	my @accs = sort keys %seqs;

	
	for (my $i = 0; $i < $#accs; $i++) {
		
		my $acc_i = $accs[$i];
		my $seq_i = $seqs{$acc_i};

		open (my $fh, ">tmp.query.$$") or die $!;
		print $fh ">$acc_i\n$seq_i\n";
		close $fh;

		for (my $j = $i + 1; $j <= $#accs; $j++) {

			my $acc_j = $accs[$j];
			my $seq_j = $seqs{$acc_j};
			
			open ($fh, ">tmp.ref.$$") or die $!;
			print $fh ">$acc_j\n$seq_j\n";
			close $fh;

			## Run WigeoN
			my $cmd = "$FindBin::Bin/../WigeoN.pl -Q tmp.query.$$ -R tmp.ref.$$ -P $FindBin::Bin/../data/rRNA16S.gold.NAST_ALIGNED.fasta.cons -M $FindBin::Bin/../data/eco.prokMSA";
			
			my $ret = system($cmd);
			
			if ($ret) {
				print "## error w/ Q: $acc_i and R: $acc_j\n";
			}
		}
	}

	exit(0);

}
			
			
####
sub parse_seqs {
	my ($file) = @_;

	my %seqs;

	my $fasta_reader = new Fasta_reader($file);

	while (my $seq_obj = $fasta_reader->next() ) {
		
		my $acc = $seq_obj->get_accession();
		my $sequence = $seq_obj->get_sequence();

		$seqs{$acc} = $sequence;
	}
	
	return(%seqs);
}
