#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;

use lib ("$FindBin::Bin/../PerlLib");

use Fasta_reader;

my $usage = "usage: $0 seqs.NAST (eco|lane) \n\n";

my $NAST_file = $ARGV[0] or die $usage;
my $mask = $ARGV[1] or die $usage;

unless ($mask eq "eco" || $mask eq "lane") {
	die $usage;
}

main: {
	
	my @mask_pos = &get_mask($mask);
	
	my $fasta_reader = new Fasta_reader($NAST_file);
	
	while (my $seq_obj = $fasta_reader->next() ) {

		my $header = $seq_obj->get_header();
		my $sequence = $seq_obj->get_sequence();

		my @chars = split(//, $sequence);
		
		if (scalar(@chars) != scalar(@mask_pos)) {
			die "Error, inconsistent length between sequence and mask ";
		}
		
		@chars = &apply_mask(\@mask_pos, \@chars);

		my $masked_seq = join("", @chars);
		$masked_seq =~ s/(\S{60})/$1\n/g;

		print ">$header\n$masked_seq\n";
	}
		
	
	exit(0);
}


####
sub get_mask {
	my ($mask) = @_;

	my $filename = ($mask eq 'eco') ? "eco.prokMSA" : "lanemask.NAST";
	
	my $file = "$FindBin::Bin/masks/$filename";

	my @x = `cat $file`;
	shift @x; # rid header;
	
	my $mask_seq = join("", @x);
	$mask_seq =~ s/\s//g;

	my @vals = split(//, $mask_seq);

	return(@vals);
}

####
sub apply_mask {
	my ($mask_aref, $chars_aref) = @_;

	my @chars = @$chars_aref;

	for (my $i = 0; $i <= $#$mask_aref; $i++) {

		if ($mask_aref->[$i] eq '0' || $mask_aref->[$i] !~ /\w/) {
			
			$chars[$i] = '.';
		}
	}

	return(@chars);
}

