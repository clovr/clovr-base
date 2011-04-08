#!/usr/bin/env perl

use strict;
use warnings;

use lib ($ENV{EUK_MODULES});
use Fasta_reader;
use FindBin;


my $usage = "usage: $0 NAST.fasta\n\n";

my $nast_file = $ARGV[0] or die $usage;

my @eco_array;
{
	my $fasta_reader = new Fasta_reader("$FindBin::Bin/eco.prokMSA");
	my $seq_obj = $fasta_reader->next();
	my $seq = $seq_obj->get_sequence();
	@eco_array = split (//, $seq);
}


my $num_sequences = 0;

my @char_counter;
foreach my $pos (@eco_array) {
	push (@char_counter, {});
}

my $fasta_reader = new Fasta_reader($nast_file);
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
my $eco_position = 0;
for (my $i =0; $i <= $#char_counter; $i++) {
	if ($eco_array[$i] =~ /\w/) {
		$eco_position++;
		my $char_counter_href = $char_counter[$i];
		my @chars = reverse sort {$char_counter_href->{$a}<=>$char_counter_href->{$b}} keys %$char_counter_href;
		my $top_char = shift @chars;
		my $top_char_count = 0;
		if ($top_char) {
			$top_char_count = $char_counter_href->{$top_char};
		}
		my $char_freq = sprintf("%.3f", $top_char_count / $num_sequences);
		print "$eco_position\t$char_freq\n";
	}
}


exit(0);


		
