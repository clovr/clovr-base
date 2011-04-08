#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use Fasta_reader;

my $usage = "usage: $0 [--IGNOREGAPS] NAST1 NAST2 ...\n\n";

my @files = @ARGV;

unless (@files) { 
	die $usage;
}

my $IGNORE_GAPS_FLAG = 0;
if (grep { /--IGNOREGAPS/ } @files) {
	@files = grep { $_ !~ /--IGNOREGAPS/ } @files;
	$IGNORE_GAPS_FLAG = 1;
}


main: {

	my %maligns;
	
	my @accs;
	
	my $seqlen = 0;
	foreach my $file (@files) {
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
	}
	
	
	{
		my %tmp_maligns;
		for (my $i = 0; $i < $seqlen; $i++) {
			my $char_flag = 0;
			foreach my $acc (@accs) {
				my $char = $maligns{$acc}->[$i];
				if ($IGNORE_GAPS_FLAG && $char eq '-') {
					$char_flag = 0;
					last;
				}	
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

	my $max_aln_len = scalar(@{$maligns{$accs[0]}});
	
	my $num_accs = scalar(@accs);
	
	my $max_acc_len = 0;
	foreach my $acc (@accs) {
		my $acc_len = length($acc);
		if ($acc_len > $max_acc_len) {
			$max_acc_len = $acc_len;
		}
	}
		
	
	for (my $i = 0; $i < $max_aln_len; $i+=60) {
		my $i2 = $i + 60 -1;
		if ($i2 >= $max_aln_len) {
			$i2 = $max_aln_len - 1;
		}		
		if ($num_accs <= 3 ) {
			my $top_diff_line = &build_top_diff_line( [ @{$maligns{$accs[0]}}[$i..$i2] ],
													  [ @{$maligns{$accs[1]}}[$i..$i2] ]);
			$top_diff_line =~ s/\!/</g;
			print( (" " x ($max_acc_len+1)) . $top_diff_line . "\n");
		}
														
		foreach my $acc (@accs) {
			
			printf("%${max_acc_len}s %s\n", $acc, join("", @{$maligns{$acc}}[$i..$i2]));
		}
		
		if ($num_accs == 3) {
			my $bottom_diff_line = &build_top_diff_line( [ @{$maligns{$accs[1]}}[$i..$i2] ],
													  [ @{$maligns{$accs[2]}}[$i..$i2] ]);
			$bottom_diff_line =~ s/\!/>/g;
			print( (" " x ($max_acc_len+1)) . $bottom_diff_line . "\n");

		}
		
		print "\n";
	}
	

	exit(0);
}

####
sub build_top_diff_line {
	my ($arefA, $arefB) = @_;

	my $matchLine = "";
	
	for (my $i = 0; $i <= $#$arefA; $i++) {
		my $charA = $arefA->[$i];
		my $charB = $arefB->[$i];
		
		if ((uc $charA) ne (uc $charB) && $charA ne '.' && $charB ne '.') {
			$matchLine .= "!";
		}
		else {
			$matchLine .= " ";
		}
	}

	return($matchLine);
}
