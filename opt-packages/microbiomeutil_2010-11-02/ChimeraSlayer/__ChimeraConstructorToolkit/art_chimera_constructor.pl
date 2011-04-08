#!/usr/bin/env perl

use strict;
use warnings;
use Carp;

use FindBin;
use lib ("/seq/microbiome/Tool-Dev/microbiomeutil/CMCS/PerlLib/");
use AlignCompare;

use Fasta_reader;
use CdbTools;

srand();

my $usage = "usage: $0 NAST  TaxonPerID_File [ChimeraLength]\n\n";

my $NAST = $ARGV[0] or die $usage;
my $taxon_perID_file = $ARGV[1] or die $usage;

my $chimera_length = $ARGV[2] || undef;


my %eco_ref_positions;
my $eco_seq_length = 0;
my @eco_chars;

## Process the E. coli reference sequence alignment
{
	my $fasta_reader = new Fasta_reader("/seq/annotation/mbiome/Eco16S/eco.prokMSA");
	my $eco_obj = $fasta_reader->next();
	my $sequence = $eco_obj->get_sequence();
	
	my $seq_pos = 0;
	my @chars = split (//, $sequence);
	@eco_chars = @chars;
	for (my $i = 0; $i <= $#chars; $i++) {
		my $char = $chars[$i];
		if ($char =~ /[A-Z]/i) {
			$seq_pos++;
			$eco_ref_positions{$seq_pos} = $i+1; # coordinates are 1-based
		}
	}
	$eco_seq_length = $seq_pos;
}




my %alignments = &parse_alignments($NAST);

my @accs = keys %alignments;

my $left_chimera_limit = 200;
my $right_chimera_limit = 1200;
my $chimera_nonbreak_end_size = 50; # at least 100 bp of parent sequence from each end of chimera.

if (defined($chimera_length) && $chimera_length < 2*$chimera_nonbreak_end_size + 1) {
	die "Error, chimera length too short (min " . 2*$chimera_nonbreak_end_size + 1;
}

open (my $fh, $taxon_perID_file) or die $!;
while (<$fh>) {
	chomp;
	unless (/\w/) { next; }
	
	my ($taxon_level_same, $accA, $taxonomyA, $accB, $taxonomyB, $perID) = split (/\t/);
	
	if ($taxon_level_same eq "SPECIES") { next; } # ignoring same-species chimeras

	my $nast_i_seq = $alignments{$accA};
	my $nast_j_seq = $alignments{$accB};
	
	my $per_id = &AlignCompare::compute_per_ID($nast_i_seq, $nast_j_seq);
	
	if ($per_id == 100) { next; }
	
	my $BUILT_CHIMERA = 0;
	
	for (1..100) {
		
		eval {
			
			
			my @nast_i_chars = split (//, $nast_i_seq);
			my @nast_j_chars = split (//, $nast_j_seq);
			
			#my $divergence = sprintf("%.2f", 100 - &AlignCompare::compute_per_ID($nast_i_seq, $nast_j_seq));
			
			
			my $chimera_acc = "";
			
			my $clip_pt;
			my $nast_clip_pos;
			my $clip_token;

			
			if ($chimera_length) {
				
				$chimera_acc = "L$chimera_length";
				
				my $left_part_chimera = $chimera_nonbreak_end_size + int(rand($chimera_length - 2*$chimera_nonbreak_end_size));
				my $right_part_chimera = $chimera_length - $left_part_chimera;
				
				## clip point can be anywhere between ($left_part_chimera -> (length-$right_part_chimera)
				$clip_pt = int(rand($eco_seq_length - $chimera_length)) + $left_part_chimera;
				$nast_clip_pos = $eco_ref_positions{$clip_pt};
				
				# Zap before and after chars:
				my $left_clip_pos = &AlignCompare::define_left_clip(\@nast_i_chars, $nast_clip_pos -2, $left_part_chimera);
				for (my $i = 0; $i < $left_clip_pos; $i++) {
					$nast_i_chars[$i] = '.';
				}
				
				my $right_clip_pos = &AlignCompare::define_right_clip(\@nast_j_chars, $nast_clip_pos - 1, $right_part_chimera);
				for (my $j = $right_clip_pos + 1; $j <= $#nast_j_chars; $j++) {
					$nast_j_chars[$j] = '.';
				}
				
				$clip_token = ($left_clip_pos+1) . "-$nast_clip_pos:" . ($nast_clip_pos + 1) . "-" . ($right_clip_pos + 1);
				
				
			}
			else {
				
				## Full-length
				
				## pick a clip point between 200 and 1200
				$clip_pt = int(rand($right_chimera_limit - $left_chimera_limit)) + $left_chimera_limit;
			
				$nast_clip_pos = $eco_ref_positions{$clip_pt};
				
				$clip_token = "1-$nast_clip_pos" . ":" . ($nast_clip_pos+1) . "-" . length($nast_j_seq);
			}
			
			my $align_i = join("", @nast_i_chars);
			my $align_j = join("", @nast_j_chars);
			my $divergence = sprintf("%.2f", 100 - &AlignCompare::compute_per_ID($align_i, $align_j));
			
			
			my $left_chimera = join("", @nast_i_chars[0..$nast_clip_pos-2]);
			my $right_chimera = join("", @nast_j_chars[$nast_clip_pos-1..$#nast_j_chars]);
			
			my $chimera_seq = lc($left_chimera) . uc ($right_chimera);
			
			# $chimera_seq =~ s/[\.\-]//g; print "$chimera_seq\n"; ## DEBUGGING
			
			## for comparison sake, pull out left_j and right_i
			my $left_j_chars = join("", @nast_j_chars[0..$nast_clip_pos-2]);
			my $right_i_chars = join("", @nast_i_chars[$nast_clip_pos-1..$#nast_j_chars]);

			if (&count_GATC($left_chimera) < $chimera_nonbreak_end_size
				|| 
				&count_GATC($right_chimera) < $chimera_nonbreak_end_size
				||
				&count_GATC($left_j_chars) < $chimera_nonbreak_end_size
				||
				&count_GATC($right_i_chars) < $chimera_nonbreak_end_size) {
				
				die "Error, breakpoint chosen such that one end is less than $chimera_nonbreak_end_size bases ";
			}
			
			
			my $per_div_left = sprintf("%.2f", 100 - &AlignCompare::compute_per_ID($left_chimera, $left_j_chars));
			my $per_div_right = sprintf("%.2f", 100 - &AlignCompare::compute_per_ID($right_chimera, $right_i_chars));
			
			
			if ($chimera_length) {
				# ensure chimera seq length
				my $copy = $chimera_seq;
				$copy =~ s/[\.\-]//g;
				my $copy_len = length($copy);
				if ($copy_len != $chimera_length) {
					die "Error, $copy_len != $chimera_length chimera length";
				}
			}
			
			my $avg_div = int( ($per_div_left + $per_div_right)/2 + 0.5);
			
			
			$chimera_acc .= "chmraD$avg_div" . "_" . $accA . "_" . $clip_token . "_" . $accB;
			
			
			if ($per_div_left > 0 && $per_div_right > 0 && abs($per_div_left - $per_div_right) / $divergence < 0.1) {
				
				print "$taxon_level_same\t$accA\t$per_div_left\tE:$clip_pt,N:$nast_clip_pos\t$accB\t$per_div_right\t$accA: $taxonomyA\t$accB: $taxonomyB\tDiv: $divergence\t$chimera_acc\t$chimera_seq\n";
				
				$BUILT_CHIMERA = 1;
			
			}
		};
		
		
		if ($@) {
			print STDERR "Error, couldn't compare $accA to $accB: $@\n";
		}
		
		if ($BUILT_CHIMERA) {
			last;
		}
		
	}

	unless ($BUILT_CHIMERA) {
		print "#$taxon_level_same\t$accA, $accB\tNONE\n";
	}
	
}



exit(0);


####
sub count_GATC {
	my ($seq) = @_;

	my $count = 0;
	
	while ($seq =~ /[gatc]/gi) {
		$count++;
	}

	return($count);
}



####
sub parse_alignments {
	my ($fasta_file) = @_;

	my $fasta_reader = new Fasta_reader($fasta_file);
	
	my %alignments;

	while (my $seq_obj = $fasta_reader->next() ) {
		
		my $acc = $seq_obj->get_accession();
		
		my $sequence = $seq_obj->get_sequence();
		
		$alignments{$acc} = $sequence;
	}
	
	return(%alignments);
}

####
sub parse_taxonomy {
	my ($file) = @_;

	my %taxonomy;

	open (my $fh, $file) or die "Error, cannot open fiel $file";
	while (<$fh>) {
		chomp;
		my ($acc, $species, $taxonomy) = split (/\t/);
		$taxonomy .= "; $species";
		
		$taxonomy{$acc} = $taxonomy;
	}
	close $fh;

	return(%taxonomy);
}


####
sub get_common_taxon_level {
	my ($taxonomyA, $taxonomyB) = @_;

	my @TAXON_LEVELS = qw (DOMAIN PHYLUM CLASS ORDER FAMILY GENUS SPECIES);

	my @taxonsA = split(/;\s+/, $taxonomyA);
	my @taxonsB = split(/;\s+/, $taxonomyB);
	
	for (my $i = $#taxonsA; $i >= 0; $i--) {
		
		if ($taxonsA[$i] eq $taxonsB[$i]) {
			return($TAXON_LEVELS[$i]);
		}
	}

	die "Error, taxonomies have nothing in common: $taxonomyA\t$taxonomyB ";
}


