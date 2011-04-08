#!/usr/bin/env perl

use strict;
use warnings;

use Carp;
use Getopt::Long qw(:config no_ignore_case bundling);
use FindBin;
use POSIX;

use lib ($ENV{EUK_MODULES});
use Fasta_reader;
use BHStats;
use List::Util qw (shuffle);
use CdbTools;

my $usage = <<_EOUSAGE_;

###############################################################################
#
#  -Q        query sequence (NAST alignment format)
#  -R        reference sequences (NAST alignment format)
#  -M        position mask  (options: eco, Lane)
#
#  plotting options:
#  --plotR     plot using R (recommended)
#
#  --winSize  default 300
#  --winStep  default 10
#
#    --parentFragmentThreshold   min percent identity required in bellerophon sequence windows (default 90)
#    --divergenceRatioThreshold  min divergence ratio for chimera assignment (default 1.1) 
#
#  --printAlignments
#
###############################################################################

_EOUSAGE_

	;


my $help_flag;
my $queryAlignFile;
my $referenceAlignFile;
my $positionMaskFile;
my $plotR;
my $winStep = 10;
my $winSize = 300;
my $parentFragmentThreshold = 90;
my $divergenceRatioThreshold = 1.1;
my $VERBOSE = 0;

my $printAlignmentsFlag = 0;

&GetOptions ( 'h' => \$help_flag,
			  'Q=s' => \$queryAlignFile,
			  'R=s' => \$referenceAlignFile,
			  'M=s' => \$positionMaskFile,
			  'plotR' => \$plotR,
			  'winStep=i' => \$winStep,
			  'winSize=i' => \$winSize,
			  'parentFragmentThreshold=f' => \$parentFragmentThreshold,
			  'divergenceRatioThreshold=f' => \$divergenceRatioThreshold,
			  'v|VERBOSE' => \$VERBOSE,
			  'printAlignments' => \$printAlignmentsFlag,
	);


unless ($queryAlignFile && $referenceAlignFile) { die $usage; }
if ($help_flag) { die $usage; }

if ($positionMaskFile) {
	if ($positionMaskFile =~ /eco/i) {
		$positionMaskFile = "$FindBin::Bin/masks/eco.prokMSA";
	}
	elsif ($positionMaskFile =~ /lane/i) {
		$positionMaskFile = "$FindBin::Bin/masks/lanemask.NAST";
	}
	
	unless (-s $positionMaskFile) {
		die "Error, cannot locate position mask file: $positionMaskFile";
	}
}


main: {
	
	my $query_alignment = &retrieve_alignments_from_file($queryAlignFile);
	my $query_acc = $query_alignment->{acc};
	
	
	my @reference_alignments = &retrieve_alignments_from_file($referenceAlignFile);

	## Apply mask to input sequences as needed.
	if ($positionMaskFile) {
		
		print STDERR "-appling mask: $positionMaskFile\n";
		
		my $mask_alignment = &retrieve_alignments_from_file($positionMaskFile);
		
		$query_alignment = &apply_mask($query_alignment, $mask_alignment);
		my @masked_reference_alignments;
		foreach my $reference_alignment (@reference_alignments) {
			my $new_ref_alignment = &apply_mask($reference_alignment, $mask_alignment);
			push (@masked_reference_alignments, $new_ref_alignment);
		}

		@reference_alignments = @masked_reference_alignments; # replace with masked
	}
	
	
	## run bellerophon algorithm.  Try each pair of reference sequences as potential parents A and B
	
	my $found_chimera = 0;
	my $max_div;
	my $max_div_val = 0;
	
	for (my $i = 0; $i < $#reference_alignments; $i++) {

		for (my $j = $i+1; $j <= $#reference_alignments; $j++) {
						
			my $parent_A = $reference_alignments[$i];
			my $parent_B = $reference_alignments[$j];
			
			my @div_ratios = &run_bellerophon($query_alignment, $parent_A, $parent_B);
			if (@div_ratios) {
				foreach my $highest_div (@div_ratios) {
					if ((!$max_div_val) ||  
						$highest_div->[0] > $max_div_val || $highest_div->[1] > $max_div_val
						) {
						$max_div = $highest_div;
						$max_div_val = ($max_div->[0] > $max_div->[1]) ? $max_div->[0] : $max_div->[1];
					}
				}
			}
		}
	}
	
	if ($max_div) {
		&report_findings(@$max_div);
	}
	else {
		print "# OK\t$query_acc\n";
	}
	
	exit(0);
}


####
sub retrieve_alignments_from_file {
	my ($file) = @_;
	
	my @alignments; # struct with:   { acc => accession, align => [align chars] }

	my $fasta_reader = new Fasta_reader($file);
	while (my $seq_obj = $fasta_reader->next()) {
		
		my $accession = $seq_obj->get_accession();
		my $sequence = uc $seq_obj->get_sequence();
		$sequence =~ s/-/\./g; # consistent gap chars.
		
		my @chars = split (//, $sequence);
		
		my @seqPos;
		my $counter = 0;
		foreach my $char (@chars) {
			if ($char =~ /\w/) {
				push (@seqPos, ++$counter);
			}
			else {
				push (@seqPos, -1);
			}
		}
		

		my $alignment_struct = { acc => $accession,
								 align => [@chars],
								 seqPos => [@seqPos],
		};
		
		push (@alignments, $alignment_struct);
	}


	if (wantarray()) {
		return(@alignments);
	}
	else {
		return($alignments[0]);
	}
}

####
sub apply_mask {
	my ($alignment, $mask) = @_;

	my @align_chars  = @{$alignment->{align}};
	my @seqPos = @{$alignment->{seqPos}};
	
	my @mask_chars = @{$mask->{align}};

	my @new_align;
	my @new_seqPos;
	for (my $i = 0; $i <= $#align_chars; $i++) {
		my $mask_char = $mask_chars[$i];
		
		if ($mask_char !~ /n/i && $mask_char =~ /\w/ && $mask_char ne '0') {
			## wanted character.
			push (@new_align, $align_chars[$i]);
			push (@new_seqPos, $seqPos[$i]);
		}
	}

	my $new_alignment_struct = { acc => $alignment->{acc},
								 align => [@new_align],
								 seqPos => [@new_seqPos],
	};
	
	return($new_alignment_struct);
}


####
sub run_bellerophon {
	my ($query_alignment, $parent_A, $parent_B) = @_;
	
	my $gap_mask = &build_gap_mask($query_alignment, $parent_A, $parent_B);

	
	$query_alignment = &apply_mask($query_alignment, $gap_mask);
	$parent_A = &apply_mask($parent_A, $gap_mask);
	$parent_B = &apply_mask($parent_B, $gap_mask);
		
	my $query_acc = $query_alignment->{acc};
	my $parent_A_acc = $parent_A->{acc};
	my $parent_B_acc = $parent_B->{acc};

	my @Q_chars = @{$query_alignment->{align}};
	my @A_chars = @{$parent_A->{align}};
	my @B_chars = @{$parent_B->{align}};

	unless (scalar(@Q_chars) >= 2*$winSize) { 
		# nothing to examine.
		if ($VERBOSE) {
			print STDERR "Aligned sequence regions are to short to run through bellerophon: $query_acc, $parent_A_acc, $parent_B_acc, malign: " . scalar(@Q_chars) . "\n";
		}
		return;
	}
	
	
	if ($VERBOSE) {
		print "Running bellerophon:\n"
			. "Seq Q: $query_acc\t" . join ("", @Q_chars) . "\n"
			. "Seq A: $parent_A_acc\t" . join ("", @A_chars) . "\n"
			. "Seq B: $parent_B_acc\t" . join ("", @B_chars) . "\n";
	}
	
	
	my $align_length = scalar(@Q_chars);

	my $global_QA_per_id = &compute_per_id(\@Q_chars, \@A_chars, 0, $align_length-1);
	my $global_QB_per_id = &compute_per_id(\@Q_chars, \@B_chars, 0, $align_length-1);
		
	my @div_ratios;
	
	for (my $i = 0; $i <= $align_length - 2*$winSize; $i += $winStep) {
		
		my $win_left_end5 = $i;
		my $win_left_end3 = $i + $winSize -1;
		my $win_right_end5 = $i + $winSize;
		my $win_right_end3 = $i + 2*$winSize - 1;
		
		my $per_id_QLA = &compute_per_id(\@Q_chars, \@A_chars, $win_left_end5, $win_left_end3);
		my $per_id_QRB = &compute_per_id(\@Q_chars, \@B_chars, $win_right_end5, $win_right_end3);

		my $per_id_QRA = &compute_per_id(\@Q_chars, \@A_chars, $win_right_end5, $win_right_end3);
		my $per_id_QLB = &compute_per_id(\@Q_chars, \@B_chars, $win_left_end5, $win_left_end3);

		my $per_id_LAB = &compute_per_id(\@A_chars, \@B_chars, $win_left_end5, $win_left_end3);
		my $per_id_RAB = &compute_per_id(\@A_chars, \@B_chars, $win_right_end5, $win_right_end3);
		
		my $per_id_AB = ($per_id_LAB + $per_id_RAB) / 2;
		my $per_id_QA = ($per_id_QLA + $per_id_QRA) / 2;
		my $per_id_QB = ($per_id_QLB + $per_id_QRB) / 2;
		
		my $avg_per_id_QA_QB = ($per_id_QA + $per_id_QB) / 2;

		my $div_ratio_QLA_QRB = ($per_id_QLA+$per_id_QRB)/2/$per_id_AB;
		
		my $div_ratio_QRA_QLB = ($per_id_QRA+$per_id_QLB)/2/$per_id_AB;
		
		if ( 
			
			( $div_ratio_QLA_QRB > $divergenceRatioThreshold
			  &&
			  $per_id_QLA >= $parentFragmentThreshold
			  &&
			  $per_id_QRB >= $parentFragmentThreshold
			)
			
			||
			
			( $div_ratio_QRA_QLB > $divergenceRatioThreshold
			  &&
			  $per_id_QLB >= $parentFragmentThreshold
			  &&
			  $per_id_QRA >= $parentFragmentThreshold
			  
			) 
			) 
		{
			
			
			push (@div_ratios, [$div_ratio_QLA_QRB, $div_ratio_QRA_QLB,
								$per_id_QLA, $per_id_QRB, 
								$per_id_AB, $per_id_QA, $per_id_QB,
								$per_id_LAB, $per_id_RAB, 
								$per_id_QRA, $per_id_QLB,
								$win_left_end5, $win_left_end3, 
								$win_right_end5, $win_right_end3,
								$query_alignment, $parent_A, $parent_B,
								$global_QA_per_id, $global_QB_per_id,
				  ]);
			
		}
		
		
	}
	
	
	return(@div_ratios);
}

####
sub build_gap_mask {
	my (@alignments) = @_;

	my @gap_mask;
	foreach my $alignment (@alignments) {
		my @chars = @{$alignment->{align}};
		unless (@gap_mask) {
			$#gap_mask = $#chars;
		}
		for (my $i = 0; $i <= $#chars; $i++) {
			if ($chars[$i] =~ /[^gatc]/i) {
				$gap_mask[$i] = '0';
			}
		}
	}
	
	for (my $i = 0; $i <= $#gap_mask; $i++) {
		if ( !defined ($gap_mask[$i])) {
			$gap_mask[$i] = '1';
		}
	}

	my $gap_mask_struct = { acc => 'gap_mask',
							align => [@gap_mask],
	};

	return($gap_mask_struct);
}

####
sub compute_per_id {
	my ($seqA_aref, $seqB_aref, $lend, $rend) = @_;
	
	my $total_pos = 0;
	my $num_matches = 0;
	
	for (my $i = $lend; $i <= $rend; $i++) {
		$total_pos++;
		if ($seqA_aref->[$i] eq $seqB_aref->[$i]) {
			$num_matches++;
		}
	}

	
	return($num_matches/$total_pos*100);
}

####
sub report_findings {
	my ($div_ratio_QLA_QRB, $div_ratio_QRA_QLB,
		$per_id_QLA, $per_id_QRB, 
		$per_id_AB, $per_id_QA, $per_id_QB, 
		$per_id_LAB, $per_id_RAB,
		$per_id_QRA, $per_id_QLB,
		$win_left_end5, $win_left_end3,
		$win_right_end5, $win_right_end3,
		$Q, $A, $B,
		$global_QA_per_id, $global_QB_per_id) = @_;
	
	my @Q_chars = @{$Q->{align}};
	my @A_chars = @{$A->{align}};
	my @B_chars = @{$B->{align}};
	
	my $query_acc = $Q->{acc};
	my $A_acc = $A->{acc};
	my $B_acc = $B->{acc};
	
	my $break_left = $Q->{seqPos}->[$win_left_end3];
	my $break_right = $Q->{seqPos}->[$win_right_end5];
	
	print "//\n## CHIMERA_REPORT\t$query_acc\t$break_left-$break_right" 
		. "\tGlblQA: " . sprintf("%.2f", $global_QA_per_id) 
		. "\tGlblQB: " . sprintf("%.2f", $global_QB_per_id)
		. "\tDIV_QLARB: ". sprintf("%.3f", $div_ratio_QLA_QRB)
		. "\tDIV_QRALB: " . sprintf("%.3f", $div_ratio_QRA_QLB)
		. "\t$A_acc\t$B_acc" 
		. "\tbreakpoint: $break_left-$break_right\n\n";
	
	## draw illustration:
	
	print "            Per_id parents: " . sprintf("%.2f", $per_id_AB) . "\n\n";
	print "           Per_id(Q,A): " . sprintf("%.2f", $per_id_QA) . "\n";
	print "---------------------------------------------- A: $A_acc\n"
		. " " . sprintf("%.2f", $per_id_QLA) . "                                " . sprintf("%.2f", $per_id_QRA) . "\n"
		. "~~~~~~~~~~~~~~~~~~~\\ /~~~~~~~~~~~~~~~~~~~~~~~~ Q: $query_acc\n"
		. "DivR: " . sprintf("%.3f", $div_ratio_QLA_QRB) . "\n"
		. "                    |\n"
		. "   (L-AB: " . sprintf("%.2f", $per_id_LAB) . ")    |      (R-AB: " . sprintf("%.2f", $per_id_RAB) . ")\n"
		. "                    |\n"
		. "DivR: " . sprintf("%.3f", $div_ratio_QRA_QLB) . "\n"
		. "~~~~~~~~~~~~~~~~~~~/ \\~~~~~~~~~~~~~~~~~~~~~~~~~ Q: $query_acc\n"
		. " " . sprintf("%.2f", $per_id_QLB) . "                                " . sprintf("%.2f", $per_id_QRB) . "\n"
		. "----------------------------------------------- B: $B_acc\n";
	print "            Per_id(Q,B): ". sprintf("%.2f", $per_id_QB) . "\n\n";
	
	my $deltaL = $per_id_QLA - $per_id_QLB;
	my $deltaR = $per_id_QRA - $per_id_QRB;

	print "DeltaL: " . sprintf("%.2f", $deltaL) . "                   DeltaR: " . sprintf("%.2f", $deltaR) . "\n\n";
	
	unless ($printAlignmentsFlag) { return; }
	
	
	## build the left windows:
	my @Q_left_win = @Q_chars[$win_left_end5..$win_left_end3];
	my @A_left_win = @A_chars[$win_left_end5..$win_left_end3];
	my @B_left_win = @B_chars[$win_left_end5..$win_left_end3];
	
	&print_alignment($A_acc, \@A_left_win, 
					 $query_acc, \@Q_left_win, 
					 $B_acc, \@B_left_win);
	
	print "\t\t** Breakpoint **\n\n";
	
	my @Q_right_win = @Q_chars[$win_right_end5..$win_right_end3];
	my @A_right_win = @A_chars[$win_right_end5..$win_right_end3];
	my @B_right_win = @B_chars[$win_right_end5..$win_right_end3];
	
	&print_alignment($A_acc, \@A_right_win, 
					 $query_acc, \@Q_right_win, 
					 $B_acc, \@B_right_win);
	
	return;
}


####
sub print_alignment {
	my ($A_acc, $A_aref, $Q_acc, $Q_aref, $B_acc, $B_aref) = @_;

	my $top_mismatch_string = "";
	my $A_string = "";
	my $Q_string = "";
	my $B_string = "";
	my $bottom_mismatch_string = "";
	
	my $cut_point = 60;
	my $counter = 0;
	
	for (my $i = 0; $i <= $#$A_aref; $i++) {
		my $A_char = $A_aref->[$i];
		my $Q_char = $Q_aref->[$i];
		my $B_char = $B_aref->[$i];
		

		if ($A_char eq $Q_char && $Q_char eq $B_char) {
			$A_char = lc $A_char;
			$B_char = lc $B_char;
			$Q_char = lc $Q_char;
		
			next; 
		}
		else {
			
			if ($A_char ne $Q_char) {
				$top_mismatch_string .= "!";
			}
			else {
				$top_mismatch_string .= " ";
			}
			if ($B_char ne $Q_char) {
				$bottom_mismatch_string .= "!";
			}
			else {
				$bottom_mismatch_string .= " ";
			}
		}
		
		$A_string .= $A_char;
		$Q_string .= $Q_char;
		$B_string .= $B_char;
		
		$counter++;
		
		if ( $counter % $cut_point == 0) {
			print join("\n", $top_mismatch_string, "$A_string  A: $A_acc", "$Q_string  Q: $Q_acc", "$B_string  B: $B_acc", $bottom_mismatch_string) . "\n\n";
			$top_mismatch_string = "";
			$A_string = "";
			$Q_string = "";
			$B_string = "";
			$bottom_mismatch_string = "";
		}
	}
	
	if ($A_string) {
		print join("\n", $top_mismatch_string, "$A_string  A: $A_acc", "$Q_string  Q: $Q_acc", "$B_string  B: $B_acc", $bottom_mismatch_string) . "\n\n";
	}
	
	return;
}
