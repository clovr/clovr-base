#!/usr/bin/env perl

use strict;
use warnings;
use Fasta_reader;
use Carp;


my $usage = "usage: $0 db.NAST percentMutation\n\n";

my $db_NAST = $ARGV[0] or die $usage;
my $percent_mutation = $ARGV[1] or die $usage;


main: {
	
	my $fasta_reader = new Fasta_reader($db_NAST);
	
	while (my $seq_obj = $fasta_reader->next()) {
		
		my $header = $seq_obj->get_header();
		my $sequence = lc $seq_obj->get_sequence();

		$sequence = &evolve($sequence, $percent_mutation);
		
		print ">$header [Evolved $percent_mutation\%]\n$sequence\n";
	}

	exit(0);
}


####
sub evolve {
	my ($sequence, $percent_mutation) = @_;

	my @chars = split(//, $sequence);
	
	my @char_positions;
	
	for (my $i = 0; $i < $#chars; $i++) {
		
		my $char = $chars[$i];
		if ($char =~ /\w/ && $char !~ /n/i) {
			push (@char_positions, $i);
		}
	}
	
	my $num_positions = scalar(@char_positions);
	
	my $num_mutations = int($num_positions * $percent_mutation / 100 + 0.5);
		
	my $count_mutations = 0;
	while ($count_mutations < $num_mutations) {
		
		my $pos_index = int(rand($num_positions)) ;
		
		my $pos = $char_positions[$pos_index]; 
		
		if ($pos < 0) { next; }
		
		my $char = $chars[$pos];
		
		my @mutations = grep { $_ !~ /$char/i } qw (g a t c);
		
		my $mutation = $mutations[ int(rand(3)) ];
		
		#print "$pos\t$chars[$pos] => $mutation\n";
		
		$chars[$pos] = uc $mutation;
		$char_positions[$pos_index] = -1; # no double hits
	
		$count_mutations++;

		

	}
	
	return( join("", @chars) );
}

