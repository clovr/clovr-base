#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use Fasta_reader;

my $usage = "usage: $0 file.mfasta\n\n";

my $file = $ARGV[0] or die $usage;


main: {
	
	my %maligns;
	
	my @accs;
	
	my $seqlen = 0;
	my $fasta_reader = new Fasta_reader($file);
	while (my $seq_obj = $fasta_reader->next()) {
		my $acc = $seq_obj->get_accession();
		push (@accs, $acc);
		my $sequence = $seq_obj->get_sequence();
		my @chars = split (//, $sequence);
		$maligns{$acc} = [@chars];
		if ($seqlen && length($sequence) != $seqlen) {
			die "Error, inconsistent seqlengths";
		}
		else {
			$seqlen = length($sequence);
		}
	}
		
	{
		my %tmp_maligns;
		for (my $i = 0; $i < $seqlen; $i++) {
			my $char_flag = 0;
			foreach my $acc (@accs) {
				my $char = $maligns{$acc}->[$i];
				
				if ($char =~ /\w/) {
					$char_flag = 1;
				}
			}
			if ($char_flag) {
				foreach my $acc (@accs) {
					my $char = $maligns{$acc}->[$i];
					push (@{$tmp_maligns{$acc}}, $char);
				}
			}
		}
		
		%maligns = %tmp_maligns;
	}


	foreach my $acc (keys %maligns) {
		my $align = $maligns{$acc};
		print ">$acc\n" . join ("", @$align) . "\n";
	}
	
	exit(0);
}

