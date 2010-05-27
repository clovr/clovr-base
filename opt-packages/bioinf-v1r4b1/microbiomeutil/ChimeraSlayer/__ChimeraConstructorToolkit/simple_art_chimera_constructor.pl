#!/usr/bin/env perl

use strict;
use warnings;

use lib ("/seq/microbiome/Tool-Dev/microbiomeutil/CMCS/PerlLib/");
use Fasta_reader;
use AlignCompare;

use List::Util qw (min max);

use Data::Dumper;

my $usage = "usage: $0 TemplateSeqs.NAST [numRounds=10]\n\n";

my $template_nast = $ARGV[0] or die $usage;

my $NUM_ITER = $ARGV[1] || 10;


my %acc_to_NAST;
{
	my $fasta_reader = new Fasta_reader($template_nast);
	while (my $seq_obj = $fasta_reader->next()) {
		my $acc = $seq_obj->get_accession();
		my $sequence = $seq_obj->get_sequence();
		
		$acc_to_NAST{$acc} = $sequence;
	}
}

## build chimeras


my @accs = sort keys %acc_to_NAST;

srand();

my $NUM_END = 20; #percent

for my $iter (1..$NUM_ITER) {

	for (my $i = 0; $i < $#accs; $i++) {

		for (my $j = $i + 1; $j <= $#accs; $j++) {

			my $acc_i = $accs[$i];
			my $acc_j = $accs[$j];
			
			my $seq_i = $acc_to_NAST{$acc_i};
			my $seq_j = $acc_to_NAST{$acc_j};

			## map bounds of alignment
			my ($lend_i, $rend_i) = &AlignCompare::find_ends_of_alignment(split(//, $seq_i));
			my ($lend_j, $rend_j) = &AlignCompare::find_ends_of_alignment(split(//, $seq_j));
			
			#print "$lend_i\t$rend_i\t$lend_j\t$rend_j\n";

			my ($max_lend) = max($lend_i, $lend_j);
			my ($min_rend) = min($rend_i, $rend_j);

			## get list of possible cutpoints:
			my @nast_positions = &get_NAST_positions($seq_i, $max_lend, $min_rend);
			
			unless (@nast_positions) {
				die "Error, no possible breakpoint";
			}

			## pick a random break
			my $break_index = int (rand scalar(@nast_positions));
			my $nast_break= $nast_positions[$break_index];
			
			my $chimera_seq = lc(substr($seq_i, 0, $nast_break+1)) . uc(substr($seq_j, $nast_break+1));
			
			if (length($chimera_seq) != length($seq_i)) {
				die "inconsistent sequence lengths";
			}

			my $new_acc = join("_", ("chim$iter", $acc_i, $acc_j, $nast_break));
			print ">$new_acc\n$chimera_seq\n";
		}
							   
	}
}


####
sub get_NAST_positions {
	my ($seq, $lend, $rend) = @_;

	#print "$lend, $rend\n";

	my @nast_pos;
	
	my @chars = split(//, $seq);
	
	for (my $i = $lend + 1; $i < $rend; $i++) {
		if ($chars[$i] =~ /\w/) {
			push (@nast_pos, $i);
		}
	}
	
	#print Dumper(\@nast_pos);

	## trim off the percent of region needed to stay on the sides of the breakpoint
	my $num_pos = scalar(@nast_pos);
	my $num_at_ends = int($NUM_END/100 * $num_pos + 0.5);
	
	for (1..$num_at_ends) {
		shift @nast_pos;
		pop @nast_pos;
	}
	
	return(@nast_pos);
}



