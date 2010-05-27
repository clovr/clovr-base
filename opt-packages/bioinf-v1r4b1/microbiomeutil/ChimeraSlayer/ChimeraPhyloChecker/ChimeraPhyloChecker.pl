#!/usr/bin/env perl

use strict;
use warnings;

use Carp;
use Getopt::Long qw(:config no_ignore_case bundling);
use FindBin;
use POSIX;

use lib ("$FindBin::Bin/../PerlLib");
use Fasta_reader;
use BHStats;
use List::Util qw (shuffle);
use CdbTools;
use AlignCompare;
use NAST_to_Eco_coords;

my $usage = <<_EOUSAGE_;

###############################################################################
#
#  --query_NAST        query sequence (NAST alignment format)
#  --db_NAST           reference sequences (NAST alignment format)
#
#  plotting options:
#  --plotR     plot using R (recommended)
#
#  --winSize  default 50 (minimum sequence window size)
#  --winStep  default 5
#
#  -P    min percent identity required in sequence windows (default 90)
#  -R    min divergence ratio for chimera assignment (default 1.007) 
#  --minBS  90
#  --MAX_CHIMERA_PARENT_PER_ID  (default: 100; turned off)
#  -S    percent of SNPs to sample on each side of breakpoint for computing bootstrap support (default: 10)
#
#  --printAlignments
#
#  Debugging options:
#  -X  print all candidate chimera breakpoints, not just the best one.
#      --print_bootstraps    prints the selected snps for boostrapping
#  --showSimilarityProfiles  plots query-to-parent sequence similarity across windows of winSize
#  -v verbose
#
###############################################################################

_EOUSAGE_

	;


my $help_flag;
my $query_NAST;
my $db_NAST;
my $positionMaskFile;
my $plotR;
my $winStep = 5;
my $winSize = 50;
my $minPerID = 90;
my $divergenceRatioThreshold = 1.007;
my $VERBOSE = 0;
my $minBS = 90;
my $printAlignmentsFlag = 0;
my $PRINT_BOOTSTRAPS = 0;

my $MAX_CHIMERA_PARENT_PER_ID = 100;
my $NUM_BS_REPLICATES = 100;
my $print_All_findings = 0;

my $MIN_SNPs = 4;
my $showSimilarityProfiles = 0;

my $PERCENT_SNPS_SAMPLE = 10;

&GetOptions ( 'h' => \$help_flag,
			  'query_NAST=s' => \$query_NAST,
			  'db_NAST=s' => \$db_NAST,
			  
			  'plotR' => \$plotR,
			  'winStep=i' => \$winStep,
			  'winSize=i' => \$winSize,
			  'P=f' => \$minPerID,
			  'R=f' => \$divergenceRatioThreshold,
			  'v|VERBOSE' => \$VERBOSE,
			  'printAlignments' => \$printAlignmentsFlag,
			  'X' => \$print_All_findings,
			  'showSimilarityProfiles' => \$showSimilarityProfiles,
	
			  'S=i' => \$PERCENT_SNPS_SAMPLE,

			  'print_bootstraps' => \$PRINT_BOOTSTRAPS,
			  'minBS=i' => \$minBS,
			  'MAX_CHIMERA_PARENT_PER_ID=f' => \$MAX_CHIMERA_PARENT_PER_ID,
	);


unless ($query_NAST && $db_NAST) { die $usage; }
if ($help_flag) { die $usage; }

main: {
	
	my $start_time = time();
		
	my $query_alignment = &retrieve_alignments_from_file($query_NAST);
	my $query_acc = $query_alignment->{acc};
	
	my @reference_alignments = &retrieve_alignments_from_file($db_NAST);

	if ($showSimilarityProfiles) {
		&plot_similarity_profiles($query_alignment, \@reference_alignments, $winSize);
	}
	
	
	## Try each pair of reference sequences as potential parents A and B
		
	my @all_entries;

	for (my $i = 0; $i < $#reference_alignments; $i++) {

		for (my $j = $i+1; $j <= $#reference_alignments; $j++) {
		   
			my $begin_pair_time = time();
			
			my $parent_A = $reference_alignments[$i];
			my $parent_B = $reference_alignments[$j];
			
			my $parent_A_acc = $parent_A->{acc};
			my $parent_B_acc = $parent_B->{acc};
			


			
			my @div_structs = &run_ChimeraSlayer($query_alignment, $parent_A, $parent_B);
			my @selected_div_structs;
			foreach my $div_struct (@div_structs) {
				
				
				my @snpsLeft = &get_SNPs($div_struct->{parent_A_alignment}, 
										 $div_struct->{query_alignment}, 
										 $div_struct->{parent_B_alignment}, 
										 $div_struct->{win_left_end5}, $div_struct->{win_left_end3});
				my @snpsRight = &get_SNPs($div_struct->{parent_A_alignment}, 
										  $div_struct->{query_alignment}, 
										  $div_struct->{parent_B_alignment}, 
										  $div_struct->{win_right_end5}, $div_struct->{win_right_end3});

				
				

				my $num_snps_left = scalar(@snpsLeft);
				my $num_snps_right = scalar(@snpsRight);

				## require at least 3 SNPs on both sides of break:
				unless ($num_snps_left >= $MIN_SNPs && $num_snps_right >= $MIN_SNPs) {
					if ($VERBOSE) {
						print "\tnot enough SNPs on each side of the break: $num_snps_left, $num_snps_right\n";
					}
					next; 
				}
				
				my $win_size_left = $div_struct->{win_left_end3} - $div_struct->{win_left_end5} + 1;
				my $win_size_right = $div_struct->{win_right_end3} - $div_struct->{win_right_end5} + 1;
				
				my $snp_rate_left = $num_snps_left / $win_size_left;
				my $snp_rate_right = $num_snps_right / $win_size_right;
				
				## this may not be justified... removing for now.
			 	   #my $log_ratio = log($snp_rate_left/$snp_rate_right)/log(2);
				   #if ( abs($log_ratio) >= $MAX_SNP_LOG2_RATIO ) { next; }  ## do not accept exccess snp ratio on either side of the break
								
				my ($BS_A, $BS_B) = &bootstrap_SNPs(\@snpsLeft, \@snpsRight);
				
				$div_struct->{BS_A} = $BS_A;
				$div_struct->{BS_B} = $BS_B;
				
				$div_struct->{BS_max} = &max($BS_A, $BS_B);
				
				$div_struct->{chimera_perID_max} = &max($div_struct->{per_id_QLA_QRB}, $div_struct->{per_id_QLB_QRA});
				push (@selected_div_structs, $div_struct);
			}
			push (@all_entries, @selected_div_structs) if (@selected_div_structs);

			
			my $CS_time = time() - $begin_pair_time;
			
			
			print STDERR "\rexamined parents ($parent_A_acc, $parent_B_acc)  or ($i, $j)  took $CS_time seconds    ";

		}
	}
	
	
	## compute bootstrap support
	if (@all_entries) {
		@all_entries = reverse sort {$a->{BS_max}<=>$b->{BS_max}
									 ||
										 $a->{chimera_perID_max} <=> $b->{chimera_perID_max}
		} @all_entries;
		
		
		foreach my $div_struct (@all_entries) {
			&report_findings($div_struct);
			unless ($print_All_findings) {
				last; # only report the most supported entry.
			}
		}
	}
	else {
		#print "# OK\t$query_acc\n";
	
		print join("\t", "ChimeraSlayer", $query_acc, "NULL", "NULL", 
				   "-1", "-1", "-1", 
				   "-1", "-1", "-1",
				   "NO") . "\n";
		
	}
	
	my $end_time = time();
	
	my $exec_time = $end_time - $start_time;
	
	print STDERR "\nChimeraSlayer($query_acc) took $exec_time seconds\n";
	
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
		my @nast_pos;
		my $counter = 0;
		my $nast_pos_counter = 0;
		foreach my $char (@chars) {
			if ($char =~ /\w/) {
				push (@seqPos, ++$counter);
			}
			else {
				push (@seqPos, -1);
			}
			
			push (@nast_pos, $nast_pos_counter);
			$nast_pos_counter++;
		}
		

		my $alignment_struct = { acc => $accession,
								 align => [@chars],
								 seqPos => [@seqPos],
								 nastPos => [@nast_pos],
								 
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
	my @nastPos = @{$alignment->{nastPos}};
	
	my @mask_chars = @{$mask->{align}};

	my @new_align;
	my @new_seqPos;
	my @new_nastPos;
	for (my $i = 0; $i <= $#align_chars; $i++) {
		my $mask_char = $mask_chars[$i];
		
		if ($mask_char !~ /n/i && $mask_char =~ /\w/ && $mask_char ne '0') {
			## wanted character.
			push (@new_align, $align_chars[$i]);
			push (@new_seqPos, $seqPos[$i]);
			push (@new_nastPos, $nastPos[$i]);
		}
	}

	my $new_alignment_struct = { acc => $alignment->{acc},
								 align => [@new_align],
								 seqPos => [@new_seqPos],
								 nastPos => [@new_nastPos],
								 
	};
	
	return($new_alignment_struct);
}


####
sub run_ChimeraSlayer {
	my ($query_alignment, $parent_A, $parent_B) = @_;
	

	my $query_acc = $query_alignment->{acc};
	my $parent_A_acc = $parent_A->{acc};
	my $parent_B_acc = $parent_B->{acc};
	
	my $gap_mask = &build_gap_mask($query_alignment, $parent_A, $parent_B);

	
	$query_alignment = &apply_mask($query_alignment, $gap_mask);
	$parent_A = &apply_mask($parent_A, $gap_mask);
	$parent_B = &apply_mask($parent_B, $gap_mask);
		
	my @Q_chars = @{$query_alignment->{align}};
	my @A_chars = @{$parent_A->{align}};
	my @B_chars = @{$parent_B->{align}};
	
			
	my $align_length = scalar(@Q_chars);
	
	if ($VERBOSE) {
		print "Running ChimeraSlayer:\n"
			. "Seq Q: " . join ("", @Q_chars) . "\n"
			. "Seq A: " . join ("", @A_chars) . "\n"
			. "Seq B: " . join ("", @B_chars) . "\n";
	
		print "Alignment length: $align_length\n";
	}
	
	
	my @div_ratios;
	
	for (my $i = $winSize-1; $i <= $align_length - $winSize; $i += $winStep) {
		
		my $breakpoint = $i;

		my $left_length = $breakpoint + 1;
		my $right_length = $align_length - $left_length;
		
		my $per_id_QLA = &compute_percent_identity(\@Q_chars, \@A_chars, 0, $breakpoint);
		my $per_id_QRB = &compute_percent_identity(\@Q_chars, \@B_chars, $breakpoint+1, $align_length - 1);
		
		my $per_id_QLB = &compute_percent_identity(\@Q_chars, \@B_chars, 0, $breakpoint);
		my $per_id_QRA = &compute_percent_identity(\@Q_chars, \@A_chars, $breakpoint+1, $align_length - 1);
		
		my $per_id_LAB = &compute_percent_identity(\@A_chars, \@B_chars, 0, $breakpoint);
		my $per_id_RAB = &compute_percent_identity(\@A_chars, \@B_chars, $breakpoint+1, $align_length - 1);
		
		my $per_id_AB = ($per_id_LAB*$left_length + $per_id_RAB*$right_length) / $align_length;
		my $per_id_QA = ($per_id_QLA*$left_length + $per_id_QRA*$right_length) / $align_length;
		my $per_id_QB = ($per_id_QLB*$left_length + $per_id_QRB*$right_length) / $align_length;
		
		my $per_id_QLA_QRB = ($per_id_QLA*$left_length + $per_id_QRB*$right_length)/$align_length;
		my $per_id_QLB_QRA = ($per_id_QLB*$left_length + $per_id_QRA*$right_length)/$align_length;
		
		my $avg_per_id_QA_QB = ($per_id_QA*$left_length + $per_id_QB*$right_length)/$align_length;
		
		
		my $div_ratio_QLA_QRB = &min($per_id_QLA_QRB/$per_id_QA, $per_id_QLA_QRB/$per_id_QB);
		
		my $div_ratio_QLB_QRA = &min($per_id_QLB_QRA/$per_id_QA, $per_id_QLB_QRA/$per_id_QB);
		
		if ($VERBOSE) {
			print "$query_acc\t$parent_A_acc\t$parent_B_acc\t"
				. "bp: $breakpoint\t"
				. sprintf("%.3f", $div_ratio_QLA_QRB)
				. "\t" 
				. sprintf("%.3f", $div_ratio_QLB_QRA)
				. "\n";
		}
		
		unless ($div_ratio_QLA_QRB >= $divergenceRatioThreshold || $div_ratio_QLB_QRA >= $divergenceRatioThreshold) {
			next; 
		}
		
		
		if ( 
			
			(
			 $per_id_QLA_QRB > $per_id_QA
			 &&
			 $per_id_QLA_QRB > $per_id_QB
			 &&
			 $per_id_QLA >= $minPerID
			 &&
			 $per_id_QRB >= $minPerID
			 
			)
			
			||
			(
			 $per_id_QLB_QRA > $per_id_QA
			 &&
			 $per_id_QLB_QRA > $per_id_QB
			 &&
			 $per_id_QLB >= $minPerID
			 &&
			 $per_id_QRA >= $minPerID
			 
			) 
			
			) 
		{
						
			
		    my $data_struct = { div_ratio_QLA_QRB => $div_ratio_QLA_QRB,
								div_ratio_QLB_QRA => $div_ratio_QLB_QRA,
								per_id_QLA_QRB => $per_id_QLA_QRB,
								per_id_QLB_QRA => $per_id_QLB_QRA,
								per_id_QLA => $per_id_QLA,
								per_id_QRB => $per_id_QRB,
								per_id_AB => $per_id_AB,
								per_id_QA => $per_id_QA,
								per_id_QB => $per_id_QB,
								per_id_LAB =>  $per_id_LAB,
								per_id_RAB => $per_id_RAB,
								per_id_QRA => $per_id_QRA,
								per_id_QLB => $per_id_QLB,
								win_left_end5 => 0,
								win_left_end3 => $breakpoint,
								win_right_end5 => $breakpoint+1,
								win_right_end3 => $align_length - 1,
								query_alignment => $query_alignment,
								parent_A_alignment => $parent_A,
								parent_B_alignment => $parent_B,
			};
						
			push (@div_ratios, $data_struct);
			
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
sub compute_percent_identity {
	my ($seqA_aref, $seqB_aref, $lend, $rend) = @_;
	
	
	my $seqA = join("", @$seqA_aref[$lend..$rend]);
	my $seqB = join("", @$seqB_aref[$lend..$rend]);
	
	return(&AlignCompare::compute_per_ID($seqA, $seqB));
	
}

####
sub report_findings {
	my ($data_struct) = @_;
	
	my $div_ratio_QLA_QRB = $data_struct->{div_ratio_QLA_QRB};
	my $div_ratio_QLB_QRA = $data_struct->{div_ratio_QLB_QRA};
	
	my $per_id_QLA = $data_struct->{per_id_QLA};
	my $per_id_QRB = $data_struct->{per_id_QRB};
	my $per_id_AB = $data_struct->{per_id_AB};
	my $per_id_QA = $data_struct->{per_id_QA};
	my $per_id_QB = $data_struct->{per_id_QB}; 
	my $per_id_LAB = $data_struct->{per_id_LAB};
	my $per_id_RAB = $data_struct->{per_id_RAB};
	my $per_id_QRA = $data_struct->{per_id_QRA};
	my $per_id_QLB = $data_struct->{per_id_QLB};
	my $per_id_QLB_QRA = $data_struct->{per_id_QLB_QRA};
	my $per_id_QLA_QRB = $data_struct->{per_id_QLA_QRB};
	
	my $win_left_end5 = $data_struct->{win_left_end5};
	my $win_left_end3 = $data_struct->{win_left_end3};
	my $win_right_end5 = $data_struct->{win_right_end5};
	my $win_right_end3 = $data_struct->{win_right_end3};
	my $Q = $data_struct->{query_alignment};
	my $A = $data_struct->{parent_A_alignment};
	my $B = $data_struct->{parent_B_alignment}; 
	my $BS_A = $data_struct->{BS_A};
	my $BS_B = $data_struct->{BS_B};
	
	my @Q_chars = @{$Q->{align}};
	my @A_chars = @{$A->{align}};
	my @B_chars = @{$B->{align}};
	
	my $query_acc = $Q->{acc};
	my $A_acc = $A->{acc};
	my $B_acc = $B->{acc};
	
	my $break_left = $Q->{seqPos}->[$win_left_end3];
	my $break_right = $Q->{seqPos}->[$win_right_end5];
	
	my $nast_break_left = $Q->{nastPos}->[$win_left_end3];
	my $nast_break_right = $Q->{nastPos}->[$win_right_end5];

	my ($eco_break_left, $eco_break_right) = &NAST_to_Eco_coord($nast_break_left, $nast_break_right);
	
	my $chimeraToken = (  ($BS_A >= $minBS && $div_ratio_QLA_QRB >= $divergenceRatioThreshold)
						  ||
						  ($BS_B >= $minBS && $div_ratio_QLB_QRA >= $divergenceRatioThreshold) ) ? "YES" : "NO";
	
	## Check for Max PER-ID
	if ($chimeraToken eq 'YES'
		&& 
		($per_id_QA > $MAX_CHIMERA_PARENT_PER_ID || $per_id_QB > $MAX_CHIMERA_PARENT_PER_ID)
		) {
		
		$chimeraToken = 'NO';
	}
	
	print join("\t", "ChimeraSlayer", $query_acc,
			   $A_acc, $B_acc,
			   sprintf("%.4f", $div_ratio_QLA_QRB), sprintf("%.2f", $per_id_QLA_QRB), $BS_A,
			   sprintf("%.4f", $div_ratio_QLB_QRA), sprintf("%.2f", $per_id_QLB_QRA), $BS_B,
			   $chimeraToken, 
			   "NAST:$nast_break_left-$nast_break_right",
			   "ECO:$eco_break_left-$eco_break_right",
		) . "\n";
	
	
	unless ($printAlignmentsFlag) { return; }
	
	## draw illustration:

	print "            Per_id parents: " . sprintf("%.2f", $per_id_AB) . "\n\n";
	print "           Per_id(Q,A): " . sprintf("%.2f", $per_id_QA) . "\n";
	print "--------------------------------------------------- A: $A_acc\n"
		. " " . sprintf("%.2f", $per_id_QLA) . "                                " . sprintf("%.2f", $per_id_QRA) . "\n"
		. "~~~~~~~~~~~~~~~~~~~~~~~~\\ /~~~~~~~~~~~~~~~~~~~~~~~~ Q: $query_acc\n"
		. "DivR: " . sprintf("%.3f", $div_ratio_QLA_QRB) . " BS: " . sprintf("%.2f", $BS_A) . "     |\n"
		. "Per_id(QLA,QRB): " . sprintf("%.2f", $per_id_QLA_QRB) . "   |\n"
		. "                         |\n"
		. "   (L-AB: " . sprintf("%.2f", $per_id_LAB) . ")         |      (R-AB: " . sprintf("%.2f", $per_id_RAB) . ")\n"
		. "   WinL:$win_left_end5-$win_left_end3            |      WinR:$win_right_end5-$win_right_end3\n"
		. "                         |\n"
		. "Per_id(QLB,QRA): " . sprintf("%.2f", $per_id_QLB_QRA) . "   |\n"
		. "DivR: " . sprintf("%.3f", $div_ratio_QLB_QRA) . " BS: " . sprintf("%.2f", $BS_B) . "    |\n"
		. "~~~~~~~~~~~~~~~~~~~~~~~~/ \\~~~~~~~~~~~~~~~~~~~~~~~~~ Q: $query_acc\n"
		. " " . sprintf("%.2f", $per_id_QLB) . "                                " . sprintf("%.2f", $per_id_QRB) . "\n"
		. "---------------------------------------------------- B: $B_acc\n";
	print "            Per_id(Q,B): ". sprintf("%.2f", $per_id_QB) . "\n\n";
	
	my $deltaL = $per_id_QLA - $per_id_QLB;
	my $deltaR = $per_id_QRA - $per_id_QRB;

	print "DeltaL: " . sprintf("%.2f", $deltaL) . "                   DeltaR: " . sprintf("%.2f", $deltaR) . "\n\n";
	

	
	
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
			next; 
		}
		else {
			
			if ($A_char ne $Q_char && $Q_char !~ /x/i) {
				$top_mismatch_string .= "!";
			}
			else {
				$top_mismatch_string .= " ";
			}
		
			if ($B_char ne $Q_char && $Q_char !~ /x/i) {
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

####
sub get_SNPs {
	my ($A_alignment, $Q_alignment, $B_alignment, $left_index, $right_index) = @_;

	#print "get_SNPs(): $A_chars_aref, $Q_chars_aref, $B_chars_aref, $left_index, $right_index\n";
	

	my @snps;

	for (my $i = $left_index; $i <= $right_index; $i++) {
		
		my $A_char = $A_alignment->{align}->[$i];
		my $Q_char = $Q_alignment->{align}->[$i];
		my $B_char = $B_alignment->{align}->[$i];
		
		my $max = $#{$A_alignment->{align}};

		if ($A_char ne $Q_char || $Q_char ne $B_char) {
			
			## ensure not neighboring a gap!
			if ( 
				
				# A alignment not in gap region
				( $i == 0 || abs ($A_alignment->{seqPos}->[$i] - $A_alignment->{seqPos}->[$i-1]) == 1)
				&&
				( $i == $max || abs ($A_alignment->{seqPos}->[$i] - $A_alignment->{seqPos}->[$i+1]) == 1)
				&&
				
				# B alignment not in gap region
				( $i == 0 || abs ($Q_alignment->{seqPos}->[$i] - $Q_alignment->{seqPos}->[$i-1]) == 1)
				&&
				( $i == $max || abs ($Q_alignment->{seqPos}->[$i] - $Q_alignment->{seqPos}->[$i+1]) == 1)
				&&
				
				# C alignment not in gap region
				( $i == 0 || abs ($B_alignment->{seqPos}->[$i] - $B_alignment->{seqPos}->[$i-1]) == 1)
				&&
				( $i == $max || abs ($B_alignment->{seqPos}->[$i] - $B_alignment->{seqPos}->[$i+1]) == 1)
				) 
			{
				
				
				push (@snps, [$A_char, $Q_char, $B_char] );
			}
		}
	}
	
	return(@snps);
}


sub bootstrap_SNPs {
	my ($snpsLeft_aref, $snpsRight_aref) = @_;

	srand();

	my $count_A = 0; ## sceneario QLA,QRB supported
	my $count_B = 0; ## sceneario QLB,QRA supported
	
	my @SNPs_left = @$snpsLeft_aref;
	my @SNPs_right = @$snpsRight_aref;

	my $num_snps_left = scalar(@SNPs_left);
	my $num_snps_right = scalar(@SNPs_right);

	unless (@SNPs_left && @SNPs_right) { 
		return(0,0);
	}


	if ($PRINT_BOOTSTRAPS) {
		&print_SNP_sets($snpsLeft_aref, $snpsRight_aref);
	}

	my $num_sample_left = &max(1, int($num_snps_left * $PERCENT_SNPS_SAMPLE/100 + 0.5));
	my $num_sample_right = &max(1, int($num_snps_right * $PERCENT_SNPS_SAMPLE/100 + 0.5));
	
	for my $iter (1..$NUM_BS_REPLICATES) {
		
		
		## random sampling with replacement.
		
		my @selected_Left;
		for (1..$num_sample_left) {
			my $index = int(rand($num_snps_left));
			push (@selected_Left, $SNPs_left[$index]);
		}
		
		my @selected_Right;
		for (1..$num_sample_right) {
			my $index = int(rand($num_snps_right));
			push (@selected_Right, $SNPs_right[$index]);
		}
		

		# A  ------------------------------------------
		#       QLA                     QRA
		# Q  ------------------------------------------
		#                      |
		#                      |
		# Q  ------------------------------------------
		#       QLB                     QRB
		# B  ------------------------------------------
		
		
		my $QLA = &snp_perID_QA(@selected_Left);
		my $QRA = &snp_perID_QA(@selected_Right);
		
		my $QLB = &snp_perID_QB(@selected_Left);
		my $QRB = &snp_perID_QB(@selected_Right);
		
		my $ALB = &snp_perID_AB(@selected_Left);
		my $ARB = &snp_perID_AB(@selected_Right);
		
		
		if ($QLA > $QLB && $QRB > $QRA) {
			$count_A++;
		}
		
		if ($QLB > $QLA && $QRA > $QRB) {
			$count_B++;
		}
		
		if ($PRINT_BOOTSTRAPS) {
			&print_SNP_sets(\@selected_Left, \@selected_Right);
			
		}
		
	}

	my $percent_support_A = $count_A / $NUM_BS_REPLICATES * 100;
	my $percent_support_B = $count_B / $NUM_BS_REPLICATES * 100;

	if ($PRINT_BOOTSTRAPS) {
		print "\nBS: $percent_support_A\tBS: $percent_support_B\n";
	}
	
	
	return($percent_support_A, $percent_support_B);
}




####
sub snp_perID_QA {
	my @snps = @_;

	my $num_snps = scalar @snps;
	my $num_identical = 0;
	
	foreach my $snp (@snps) {
		my ($A, $Q, $B) = @$snp;
		if ($A eq $Q) {
			$num_identical++;
		}
	}

	return($num_identical/$num_snps*100);
}

####
sub snp_perID_QB {
	my @snps = @_;
	
	my $num_snps = scalar @snps;
	my $num_identical = 0;
	
	foreach my $snp (@snps) {
		my ($A, $Q, $B) = @$snp;
		if ($B eq $Q) {
			$num_identical++;
		}
	}
	
	return($num_identical/$num_snps*100);

}

####
sub snp_perID_AB {
	my @snps = @_;
	
	my $num_snps = scalar @snps;
	my $num_identical = 0;
	
	foreach my $snp (@snps) {
		my ($A, $Q, $B) = @$snp;
		if ($A eq $B) {
			$num_identical++;
		}
	}
	
	return($num_identical/$num_snps*100);

}

####
sub min {
	my @vals = @_;

	@vals = sort {$a<=>$b} @vals;

	my $min_val = shift @vals;
	
	return($min_val);
}

####
sub max {
	my @vals = @_;
	
	@vals = sort {$a<=>$b} @vals;
	
	my $max_val = pop @vals;
	
	return($max_val);
}

####
sub plot_similarity_profiles {
	my ($query_alignment, $reference_alignments_aref, $winSize) = @_;


	my $query_acc = $query_alignment->{acc};
	my $query_align = $query_alignment->{align};
	
	foreach my $reference_alignment (@$reference_alignments_aref) {
		
		my $ref_acc = $reference_alignment->{acc};
		my $ref_align = $reference_alignment->{align};
		
		print "\n\*Alignment similarity profile: $query_acc vs. $ref_acc\n";
		for (my $i = 0; $i < $#$ref_align - $winSize; $i += $winSize) {
			my $win_left = $i;
			my $win_right = $i + $winSize;
			if ($win_right > $#$ref_align) {
				$win_right = $#$ref_align;
			}
			my $per_id = &compute_percent_identity($query_align, $ref_align, $win_left, $win_right);
			print "$win_left-$win_right: " . sprintf("%.2f", $per_id) . "\n";
		}
	}

	return;
}
		
####
sub print_SNP_sets {
	my ($snps_left_aref, $snps_right_aref) = @_;

	my @A;
	my @B;
	my @C;

	foreach my $snp (@$snps_left_aref) {
		my ($a, $b, $c) = @$snp;
		push (@A, $a);
		push (@B, $b);
		push (@C, $c);
	}
	
	# add spacer
	push (@A, 'x', 'x', 'x', 'x');
	push (@B, 'X', 'X', 'X', 'X');
	push (@C, 'x', 'x', 'x', 'x');

	foreach my $snp (@$snps_right_aref) {
		my ($a, $b, $c) = @$snp;
		push (@A, $a);
		push (@B, $b);
		push (@C, $c);
	}

	&print_alignment("A", \@A, "B", \@B, "C", \@C);

	return;
}
