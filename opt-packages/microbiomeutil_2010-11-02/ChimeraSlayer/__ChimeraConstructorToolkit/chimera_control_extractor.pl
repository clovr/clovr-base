#!/usr/bin/env perl

use strict;
use warnings;

use CdbTools;


my $usage = "usage: $0 chimera.dat.100perdiv(file)  non-chimera.NAST(file) seqLength\n\n";

my $chimera_dat_file = $ARGV[0] or die $usage;
my $NAST_db = $ARGV[1] or die $usage;
my $seqLength = $ARGV[2] or die $usage;

my $LEFT_CHIMERA_LEN = int($seqLength/2);


open (my $fh, $chimera_dat_file) or die $!;
while (<$fh>) {
	if (/^\#/) { die "Error, use the 100/perdiv dat file"; }
	
	my $left_chimera_len = $LEFT_CHIMERA_LEN; # init

	my @x = split(/\t/);
	my $accA = $x[1];
	
	my $clip_info = $x[3];
	$clip_info =~ /,N:(\d+)/;
	my $clip_pos = $1;
	
	my $alignment = &cdbyank_linear($accA, $NAST_db);
	{
		my $copy = $alignment;
		$copy =~ s/[\.\-]//g;
		my $copy_len =length($copy);
		print STDERR "length($accA) = $copy_len\n";
		
	}
	my @chars = split(//, $alignment);
		
	## adjust clip position based on remaining length after clipping
	{
		my $left_region = substr($alignment, 0, $clip_pos);
		my $right_region = substr($alignment, $clip_pos);
		$left_region =~ s/[\.\-]//g;
		$right_region =~ s/[\.\-]//g;
		
		if (length($left_region) < $left_chimera_len) {
			$left_chimera_len = length($left_region);
		}
		if (length($right_region) < $left_chimera_len) {
			$left_chimera_len = $seqLength - length($right_region);
		}
	
		print STDERR "$accA (c:$clip_pos)\t left_len: $left_chimera_len\n";
	}

	# determine left and right clip

	# left clip
	my $count = 0;

	my $left_clip = 0;
	for (my $i = $clip_pos - 1; $i >= 0; $i--) {
		my $char = $chars[$i];
		
		if ($char =~ /\w/) {
			$count++;
			if ($count >= $left_chimera_len) {
				$left_clip = $i;
				last;
			}
		}
	}
	
	# right clip
	
	$count = 0;
	my $right_clip = 0;
	for (my $i = $clip_pos; $i<= $#chars; $i++) {
		my $char = $chars[$i];
		if ($char =~ /\w/) {
			$count++;
			
			if ($count >= $seqLength - $left_chimera_len) {
				$right_clip = $i;
				last;
			}
			
		}
	}
	
	print STDERR "\t$accA: $left_clip-$right_clip\n";
	
	for (my $i = 0; $i <= $#chars; $i++) {
		if ($i < $left_clip || $i > $right_clip) {
			$chars[$i] = ".";
		}
	}

	my $seq = join("", @chars);

	
	{ ## verify
		my $copy_seq = $seq;
		$copy_seq =~ s/[\.\-]//g;
		if (length($copy_seq) != $seqLength) {
		    print STDERR "Error, didn't create a control seq of expected length";
			
		}
	}
	

	print ">$accA\n$seq\n";
}

exit(0);



		
		
		
		
