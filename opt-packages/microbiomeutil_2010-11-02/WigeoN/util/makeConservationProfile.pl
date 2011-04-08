#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use Fasta_reader;



my $usage = "usage: $0 align.fasta\n\n";

my $align_file = $ARGV[0] or die $usage;

my $num_sequences = 0;

my @char_counter;

my $fasta_reader = new Fasta_reader($align_file);
while (my $seq_obj = $fasta_reader->next()) {
	my $header = $seq_obj->get_header();
	#print STDERR "-processing: $header\n";
	
	my $sequence = uc $seq_obj->get_sequence();
	$sequence =~ s/U/T/g;
	my @chars = split (//, $sequence);
	$num_sequences++;
	
	for (my $i = 0; $i <= $#chars; $i++) {
		my $char = $chars[$i];
		if ($char =~ /[GATC]/) {
			$char_counter[$i]->{$char}++;
		}
	}
}
			
## plot the most frequent character at Ecoli positions:
for (my $i =0; $i <= $#char_counter; $i++) {
	my $char_counter_href = $char_counter[$i];
	my @chars = reverse sort {$char_counter_href->{$a}<=>$char_counter_href->{$b}} keys %$char_counter_href;
	my $top_char = shift @chars;
	my $top_char_count = 0;
	if ($top_char) {
		$top_char_count = $char_counter_href->{$top_char};
	}
	my $char_freq = sprintf("%.3f", $top_char_count / $num_sequences);
	print "$i\t$char_freq\n";
}


exit(0);


		
