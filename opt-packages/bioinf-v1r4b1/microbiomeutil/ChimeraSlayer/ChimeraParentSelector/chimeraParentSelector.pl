#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");
use Fasta_reader;
use AlignCompare;
use NAST_to_Eco_coords;
use Getopt::Long qw(:config no_ignore_case bundling);
use List::Util qw (min max);
use Carp;
use Data::Dumper;
use POSIX;


## To do:
# percent alignment check
# trim to full ends of alignments.
# calc how better the chimera is than the full-length sequences.


my $usage = <<_EOUSAGE_;

###################################################################
#
#  Required:
#    --query_NAST      multi-fasta file containing query sequences in alignment format
#    --db_NAST        db in NAST format

#  Scoring parameters:
#   -M match score        (default: +5)
#   -N mismatch penalty   (default: -4)
#   -R min divR           (default: 1.007)  [minimum (query,chimera) / (query,parent) alignment identity ratio]
#
#  Misc:
#   -Q min query coverage   (default: 70)
#   -T max multiple alignment traverse count  (default: 1)
#
#  Flags:
#   --printAlignments     (default off)    --SHOW_ECO  to include E. coli alignment text.
#   -v     verbose
###################################################################

_EOUSAGE_
	
	;


my $help_flag;


my $MATCH_SCORE = 5;
my $MISMATCH_PENALTY = -4;
my $minDivR = 1.007;

my $queryAlignmentFile;
my $compareMalignmentFile;
my $printAlignmentsFlag = 0;
my $VERBOSE = 0;
my $minQueryCoverage = 70;

my $PRINT_TRIMMED_ALIGNMENTS = 0;
my $maxTraverse = 1;

my $SHOW_ECO = 0;

&GetOptions ( 'h' => \$help_flag,
			  
			  'query_NAST=s' => \$queryAlignmentFile,
			  'db_NAST=s' => \$compareMalignmentFile,
			  
			  "M=i" => \$MATCH_SCORE,
			  "N=i" => \$MISMATCH_PENALTY,
			  "R=f" => \$minDivR,
			  
			  "printAlignments" => \$printAlignmentsFlag,
			  "v" => \$VERBOSE,
			  
			  "Q=i" => \$minQueryCoverage,
			  "T=i" => \$maxTraverse,
			  
			  ## Hidden Debug Opts
			  "print_trimmed_alignments" => \$PRINT_TRIMMED_ALIGNMENTS,
			  
			  "SHOW_ECO" => \$SHOW_ECO,
	);

unless ($queryAlignmentFile && $compareMalignmentFile
		&& $MATCH_SCORE > 0
		&& $MISMATCH_PENALTY < 0
		) {
	die $usage;
}


my $CHIMERA_PENALTY = undef;  # set based on minDivR and query length

my $NEG_INFINITY = -999999999;

main: {
	my ($queryAlignStruct) = &parse_malignments($queryAlignmentFile);
	my @compareMalignments = &parse_malignments($compareMalignmentFile);
	
	@compareMalignments = &apply_min_query_coverage_filter($queryAlignStruct, \@compareMalignments, $minQueryCoverage);
	
	if (scalar(@compareMalignments) < 2) {
		print "ChimeraParentSelector\t" . $queryAlignStruct->{acc} . "\tUNKNOWN\n";
		exit(0);
	}
	
	$CHIMERA_PENALTY = &compute_chimera_penalty($queryAlignStruct, $minDivR);


	
	my $start_time = time();
	my $traverse_begin_time = time();
	
	my $result_struct = &chimeraMaligner($queryAlignStruct, \@compareMalignments);
	
	
	my $chimera_flag = $result_struct->{chimera_flag};
	
	print "ChimeraParentSelector\t" . $queryAlignStruct->{acc} 
	. "\t" . $result_struct->{chimera_flag};
	
	my $countTraverse = 0;
	while ($countTraverse == 0 || $chimera_flag eq "YES") {
		
		$countTraverse++;
		
		my @traces = @{$result_struct->{trace}};
		
		my $trace_text = "";
		
		my @scores;
		
		foreach my $trace (@traces) {
			my $acc = $trace->{parent_acc};
			my $region_start = $trace->{region_start};
			my $region_end = $trace->{region_end};
			my $per_id_local_QP = $trace->{QP_local_per_id};
			my $per_id_global_QP = $trace->{QP_global_per_id};
			my $divR = $trace->{global_divR};
			my $raw_segment_length = $trace->{raw_segment_length};
			
			my ($eco_region_start, $eco_region_end) = &NAST_to_Eco_coord($region_start, $region_end);
			
			$trace_text .= ";($acc, NAST:$region_start-$region_end, "
				. "ECO:$eco_region_start-$eco_region_end, "
				. "RawLen:$raw_segment_length, "
				. "G:$per_id_global_QP, "
				. "L:$per_id_local_QP, $divR)";
			
			# score it:
			my $score = (($region_end - $region_start) + 1) * $per_id_local_QP;
			push (@scores, [$score, $acc]);
			
		}
		$trace_text =~ s/^\;//; # remove first semicolon
		
		print "\t" . sprintf("%.2f", $result_struct->{QC_per_id}) . "[$trace_text]";
	
	
		if ($chimera_flag eq "YES") {
			@scores = sort {$a->[0]<=>$b->[0]} @scores;
			
			# remove top score, keep in the set, remove the rest
			pop @scores; 
			my %accs_to_remove;
			foreach my $score (@scores) {
				$accs_to_remove{ $score->[1] } = 1;
			}
			
			
			@compareMalignments = &remove_entries_from_alignment_list(\@compareMalignments, \%accs_to_remove);
			
			
			my $traverse_end_time = time();
			
			my $traverse_time = $traverse_end_time - $traverse_begin_time;
			print STDERR "\rT($countTraverse)=$traverse_time s   ";
			
			if ($countTraverse >= $maxTraverse || scalar(@compareMalignments) < 2 ) { 
				last; # enough tries
			}
			
			
			## Redo chimera maligning:
			
			$traverse_begin_time = time();
			
			$result_struct = &chimeraMaligner($queryAlignStruct, \@compareMalignments);
			
			$chimera_flag = $result_struct->{chimera_flag};
		}
		
	} 
	
	print "\n";

	my $end_time = time();
	my $total_time = $end_time - $start_time;
	
	print STDERR "\nChimeraParentSelector(" . $queryAlignStruct->{acc} . ") took $total_time seconds\n";
	
	exit(0);
	
}


####
sub chimeraMaligner {
	my ($queryAlignStruct, $compareMalignments_aref) = @_;
	
	my @compareMalignments = @$compareMalignments_aref;
	
	unless (scalar (@compareMalignments) > 1) {
		die "Error, trying to compare a query to less than 2 comparable sequences.  Impossible to have a chimera here.\n";
	}


	my ($index_left, $index_right) = &find_mult_alignment_inner_bounds($queryAlignStruct, @compareMalignments);
	#my ($index_left, $index_right) = &find_ends_of_alignment($queryAlignStruct);	
	

	print "Inner bounds of multiple alignment: $index_left-$index_right\n" if $VERBOSE;
	
	($queryAlignStruct, @compareMalignments) = &remove_allgap_cols([$queryAlignStruct, @compareMalignments], $index_left, $index_right);
	
	if ($PRINT_TRIMMED_ALIGNMENTS) {
		&print_alignments($queryAlignStruct, @compareMalignments);
		die;
	}
	
	my $alignment_length = scalar(@{$queryAlignStruct->{align}});
	my $num_compare_alignments = scalar(@compareMalignments);
	
	my @scoring_matrix = &build_scoring_matrix($alignment_length, $num_compare_alignments);
	
	&populate_scoring_matrix(\@scoring_matrix, $queryAlignStruct, \@compareMalignments);
	
	## extract optimal traceback
	my @trace = &extract_highest_scoring_path(\@scoring_matrix);
	
	if ($printAlignmentsFlag) {
		&report_alignment_trace(\@trace, $queryAlignStruct, \@compareMalignments);
	}
	
	my @trace_regions = &map_trace_regions_to_alignments(\@trace, \@compareMalignments);
	
	my $chimera_flag = (scalar(@trace_regions) > 1) ? "YES" : "NO";
		
	my $trace_start = $trace[0]->{colIndex};
	my $trace_end = $trace[$#trace]->{colIndex};
	
	my $query_alignment_in_range = &get_sequence_from_alignment_in_range($queryAlignStruct, $trace_start, $trace_end); #join("", @{$queryAlignStruct->{align}}[$trace_start..$trace_end]);
	
	my $chimera_seq = &construct_chimera_sequence(\@trace_regions, \@compareMalignments);
	
	if (0) {
		# global alignment
		print "Query_alignment:" . length($query_alignment_in_range) . "\n$query_alignment_in_range\n\n";
		print "Chimera:" . length($chimera_seq) . "\n$chimera_seq\n\n";
	}
	
	my $per_id_QC = &compute_perID($query_alignment_in_range, $chimera_seq);	
	
	my $result_struct = { chimera_flag => $chimera_flag,
						  QC_per_id => $per_id_QC,
						  trace => [],
	};
	
	# if ($chimera_flag eq "YES") {
			
		foreach my $trace_region (@trace_regions) {
			my ($region_start, $region_end, $seqIndex) = @$trace_region;
			my $alignment_obj = $compareMalignments[$seqIndex];
			my $acc = $alignment_obj->{acc};
			my $parent_alignment_in_range = &get_sequence_from_alignment_in_range($alignment_obj, $trace_start, $trace_end); #join("", @{$alignment_obj->{align}}[$trace_start..$trace_end]);
			
			## global alignment
			my $per_id_QP = &compute_perID($query_alignment_in_range, $parent_alignment_in_range);
			
			my $divR = sprintf("%.3f", $per_id_QC / $per_id_QP);
			
			$per_id_QP = sprintf("%.2f", $per_id_QP);
			#print "alignment in range: $alignment_in_range\n";
			
			my $query_region = &get_sequence_from_alignment_in_range($queryAlignStruct, $region_start, $region_end); # join("", @{$queryAlignStruct->{align}}[$region_start..$region_end]);
			my $parent_region = &get_sequence_from_alignment_in_range($alignment_obj, $region_start, $region_end); #join("", @{$alignment_obj->{align}}[$region_start..$region_end]);
			
			my $per_id_local_QP = sprintf("%.2f", &compute_perID($query_region, $parent_region));
			
			## map region endpoints to original NAST positions.
			my $nast_region_start = $alignment_obj->{align}->[$region_start]->{pos};
			my $nast_region_end = $alignment_obj->{align}->[$region_end]->{pos};
			
			my $unaligned_region_start = $alignment_obj->{align}->[$region_start]->{unaligned_pos};
			my $unaligned_region_stop = $alignment_obj->{align}->[$region_end]->{unaligned_pos};

			my $trace_struct = { 
				parent_acc => $acc,
				region_start => $nast_region_start,
				region_end => $nast_region_end,
				QP_global_per_id => $per_id_QP,
				QP_local_per_id => $per_id_local_QP,
				global_divR => $divR,
				raw_segment_length => $unaligned_region_stop - $unaligned_region_start + 1,
			};
			
			push (@{$result_struct->{trace}}, $trace_struct);
		}
		
			
     #}
	
	return ($result_struct);
	
}


####
sub remove_allgap_cols {
	my ($align_structs_aref, $index_left, $index_right) = @_;
	
	my @align_structs = @$align_structs_aref;
	
	## create copies with initialized alignment objects as empty
	my @ret_aligns;
	my %ret_aligns_by_acc;

	foreach my $align_struct (@align_structs) {
		my $ret_struct = { acc => $align_struct->{acc},
						   align => [],
		};
		push (@ret_aligns, $ret_struct);
		$ret_aligns_by_acc{$align_struct->{acc}} = $ret_struct;
	}

	my $align_length = scalar (@{$align_structs[0]->{align}});
	
	for (my $i = $index_left; $i <= $index_right; $i++) {
		
		my $got_char = 0;
		foreach my $align (@align_structs) {
			if ($align->{align}->[$i]->{char} =~ /\w/) {
				$got_char = 1;
				last;
			}
		}

		if ($got_char) {
			foreach my $align (@align_structs) {
				my $acc = $align->{acc};
				my $ret_align = $ret_aligns_by_acc{$acc};
				my $char_struct = $align->{align}->[$i];
				push (@{$ret_align->{align}}, $char_struct);
			}
		}
	}

	return(@ret_aligns);
}




####
sub parse_malignments {
	my ($file) = @_;

	my @align_structs;

	my $fasta_reader = new Fasta_reader($file);
	while (my $seq_obj = $fasta_reader->next()) {
		my $acc = $seq_obj->get_accession();
		my $sequence = uc $seq_obj->get_sequence();
		
		my $alignment_struct = &create_alignment_struct($acc, $sequence);
		
		push (@align_structs, $alignment_struct);
	}

	return(@align_structs);
}

####
sub create_alignment_struct {
	my ($acc, $sequence) = @_;

	my @chars = split (//, $sequence);
	
	## store character and position in original NAST alignment
	my @char_pos_structs;
	my $char_pos = 0;
	my $unaligned_position = 0;
	foreach my $char (@chars) {
		$char_pos++;
		
		if ($char =~ /\w/) {
			$unaligned_position++;
		}
		
		push (@char_pos_structs, { char => $char,
								   pos => $char_pos,  # NAST column starting with 1
								   unaligned_pos => $unaligned_position, # position of character in the unaligned sequence (derived from alignment, though).
								   
			  });
	}
	
    my $alignment_struct = { acc => $acc,
							 align => [@char_pos_structs] };

	return($alignment_struct);
	
}
	
####
sub build_scoring_matrix {
	my ($matrix_length, $matrix_height) = @_;
	
	my @matrix;
	# build rows
	for (1..$matrix_height) {
		push (@matrix, []);
	}
	
	# populate rows
	my $matrix_row_index = -1;
	foreach my $matrix_row (@matrix) {
		$matrix_row_index++;
		for my $col (1..$matrix_length) {
			my $score_struct = { prev => -1,
								 score => $NEG_INFINITY,
								 seqIndex => $matrix_row_index,
								 colIndex => $col - 1,
			};
			push (@$matrix_row, $score_struct);
		}
	}
	
	return(@matrix);
}

####
sub populate_scoring_matrix {
	my ($scoring_matrix_aref, $queryAlignmentStruct, $compareMalignments_aref) = @_;

	#print Dumper ($queryAlignmentStruct);
	#print Dumper ($compareMalignments_aref);

	## extract matrix dimensions
	my $matrix_rows = scalar(@$scoring_matrix_aref);
	my $matrix_length = scalar(@{$scoring_matrix_aref->[0]});
	
	## init the first column
	{
		my $query_char = $queryAlignmentStruct->{align}->[0]->{char};
		for (my $seqIndex = 0; $seqIndex < $matrix_rows; $seqIndex++) {
			my $compare_align = $compareMalignments_aref->[$seqIndex];
			my $compare_char = $compare_align->{align}->[0]->{char};
						
			if ($query_char =~ /[\.-]/ && $compare_char =~ /[\.-]/) {
				$scoring_matrix_aref->[$seqIndex]->[0]->{score} = 0;
			} elsif ($compare_char eq $query_char) {
				$scoring_matrix_aref->[$seqIndex]->[0]->{score} = $MATCH_SCORE;
			}
			else {
				$scoring_matrix_aref->[$seqIndex]->[0]->{score} = 0; #$MISMATCH_PENALTY;
			}
		}
	}
	
	## populate rest of the matrix, store tracebacks
	for (my $i = 1; $i < $matrix_length; $i++) { ## iterate matrix columns (sequence positions)
			
		my $query_char = $queryAlignmentStruct->{align}->[$i]->{char};
		
		for (my $seqIndex = 0; $seqIndex < $matrix_rows; $seqIndex++) { ## iterate matrix rows (sequence alignments)
			
			my $compare_align = $compareMalignments_aref->[$seqIndex];
			my $compare_char = $compare_align->{align}->[$i]->{char};
			
			
			my $match_or_mismatch_score = 0;
			if ($query_char =~ /[\.-]/ && $compare_char =~ /[\.-]/) {
				# leave zero
			}
			elsif ($query_char eq "N" || $compare_char eq "N") {
				# leave zero
			}
			elsif ($query_char eq $compare_char) {
				$match_or_mismatch_score = $MATCH_SCORE;
			}
			elsif ($query_char ne $compare_char) {
				$match_or_mismatch_score = $MISMATCH_PENALTY;
			}
			
			## compute score based on previous column score
			for (my $prevSeqIndex = 0; $prevSeqIndex < $matrix_rows; $prevSeqIndex++) { ## iterate matrix rows
				
				my $sum_score = $match_or_mismatch_score + $scoring_matrix_aref->[$prevSeqIndex]->[$i-1]->{score};
				# print "$i $prevSeqIndex $sum_score\n";
				if ($prevSeqIndex != $seqIndex) {
					$sum_score += $CHIMERA_PENALTY;
				}
				
				if ($sum_score < 0) { $sum_score = 0; } # local alignment scoring scheme.

				if ($sum_score > $scoring_matrix_aref->[$seqIndex]->[$i]->{score}) {
					$scoring_matrix_aref->[$seqIndex]->[$i]->{score} = $sum_score;
					$scoring_matrix_aref->[$seqIndex]->[$i]->{prev} = $prevSeqIndex;
				}
			}
		}
	}
	
	return;
}


####
sub extract_highest_scoring_path {
	my ($scoring_matrix_aref) = @_;
	
	my $matrix_length = scalar(@{$scoring_matrix_aref->[0]});
	my $num_rows = scalar(@$scoring_matrix_aref);
		
	
	
	## find highest score from last column of the scoring matrix
	my $highest_scoring_struct;
	{
		my $highest_score = 0;
		my $row_count = 0;
		foreach my $row (@$scoring_matrix_aref) {
			$row_count++;
			my $col_count = 0;
			foreach my $score_struct (@$row) {
				$col_count++;
				my $score = $score_struct->{score};
				#print "($row_count, $col_count) : $score\n";
				
				if ($score_struct->{score} > $highest_score) {
					$highest_score = $score_struct->{score};
					$highest_scoring_struct = $score_struct;
				}
			}
		}
	}
	
		
	my @path;
	
	my $row_index = $highest_scoring_struct->{seqIndex};
	my $pos = $highest_scoring_struct->{colIndex};
	my $score = $highest_scoring_struct->{score};
	
	while ($pos >= 0 && $score > 0) {
		my $struct = $scoring_matrix_aref->[$row_index]->[$pos];
		$score = $struct->{score};
		push (@path, $struct) if $score > 0;
		$row_index = $struct->{prev};
		$pos--;
		
	}

	@path = reverse @path;
	
	return(@path);
}


####
sub report_alignment_trace {
	my ($trace_aref, $queryAlignStruct, $compareMalignments_aref) = @_;
	

	
	## include E. coli as reference.
	my $Eco_nast_align = &NAST_to_Eco_coords::get_Eco_NAST_alignment();
	my $Eco_alignment_struct = &create_alignment_struct("Eco", $Eco_nast_align);
	
	$Eco_alignment_struct = &filter_for_query_alignment_positions($queryAlignStruct, $Eco_alignment_struct);
	

	
	my $report_width = 60;
	my $num_seqs = scalar(@$compareMalignments_aref);
	
	
	## get trace indices
	my %traceIndices;
	foreach my $score_struct (@$trace_aref) {
		$traceIndices{$score_struct->{seqIndex}} = 1;
	}
	
	my $trace_start = $trace_aref->[0]->{colIndex};
	my $trace_end = $trace_aref->[$#$trace_aref]->{colIndex};
	
	
	my $trace_counter = 0;
	for (my $i = $trace_start; $i <= $trace_end; $i += $report_width, $trace_counter += $report_width) {
		
		
		my $alignment_rend = $i + $report_width - 1;
		if ($alignment_rend > $trace_end) {
			$alignment_rend = $trace_end;
		}

		my @region_align_chars = @{$queryAlignStruct->{align}}[$i..$alignment_rend];

		my $region_align_seq = &get_sequence_from_alignment_in_range($queryAlignStruct, $i, $alignment_rend);
		
		my @query_align_chars = split(//, uc $region_align_seq);  ## need to retool this section to avoid using similar var names.
		
		## print alignments for the comparables:
		my $alignment_counter = -2;
		
		
		foreach my $alignment ($Eco_alignment_struct, @$compareMalignments_aref) {
			$alignment_counter++;
			unless ($alignment_counter < 0 || $traceIndices{$alignment_counter}) { next; } # only print the alignments in the trace.
			my $acc = $alignment->{acc};

			my @other_align_chars = @{$alignment->{align}}[$i..$alignment_rend];
			
			## remember, align chars here are actually char structs!
			
			my ($adj_align_region_aref, $error_profile_aref) = &build_error_profile(\@other_align_chars, \@region_align_chars);
			
			my $align_region = &get_sequence_from_alignment_in_range($alignment, $i, $alignment_rend); #join ("", @$adj_align_region_aref);
			
			my @other_seq_chars = split(//, uc $align_region);
			
			## make conflicting characters lower case
			for (my $i = 0; $i <= $#other_seq_chars; $i++) {
				if ($query_align_chars[$i] ne $other_seq_chars[$i]) {
					$other_seq_chars[$i] = lc $other_seq_chars[$i];
				}
			}
			$align_region = join("", @other_seq_chars);
			
			## add Eco coordinate value
			if ($alignment eq $Eco_alignment_struct) {
				my $eco_region_position = $Eco_alignment_struct->{align}->[$i]->{unaligned_pos};
				my $Vregion = &NAST_to_Eco_coords::Eco_to_Vregion_string($eco_region_position);

				$acc .= "  $eco_region_position $Vregion";
				
				$align_region = "" unless ($SHOW_ECO);
				
			}
			
			#print(  (" " x 26) . join ("", @$error_profile_aref) . "\n");
			printf("%-25s $align_region\n", substr("$alignment_counter $acc", 0, 25), $align_region);
		}
		
		print "\n";
		
		## print the query sequence alignment region:
		printf ("%-25s %s\n", substr($queryAlignStruct->{acc}, 0, 25), $region_align_seq); #join ("", @region_align_chars));
				
		## print the path information:
		my $max_index_char_len = 0;
		my @alignIndices;

		my $max_j = $trace_counter + $report_width - 1;
		if ($max_j > $#$trace_aref) {
			$max_j = $#$trace_aref;
		}
		for (my $j = $trace_counter; $j <= $max_j; $j++) {
			my $score_struct = $trace_aref->[$j];
			#print Dumper($score_struct);
			#print "$j\n";
			

			my $seqIndex = $score_struct->{seqIndex};  ###### DEBUG
			#my $seqIndex = $score_struct->{score};
			if (length($seqIndex) > $max_index_char_len) { 
				$max_index_char_len = length($seqIndex);
			}
			push (@alignIndices, $seqIndex);
		}
		
		my @index_text_lines;
		
		foreach my $alignIndex (@alignIndices) {
			$alignIndex = $alignIndex . (" " x ($max_index_char_len - length($alignIndex)) );
			my @chars = split (//, $alignIndex);
			my $counter = 0;
			foreach my $char (@chars) {
				$index_text_lines[$counter] .= $char;
				$counter++;
			}
		}
		foreach my $index_text_line (@index_text_lines) {
			printf("%-25s %s\n", "Trace", $index_text_line);
		}
		
		print "\n\n";
	}
			
	
	return;
}

####
sub find_ends_of_alignment {
	my ($alignment_struct) = @_;
	
	my @align_array = @{$alignment_struct->{align}};
	
	my $index_left;
	my $index_right;

	for (my $i = 0; $i <= $#align_array; $i++) {
		if ($align_array[$i]->{char} =~ /\w/) {
			$index_left = $i;
			last;
		}
	}

	for (my $i = $#align_array; $i >= 0; $i--) {
		if ($align_array[$i]->{char} =~ /\w/) {
			$index_right = $i;
			last;
		}
	}
	
	return($index_left, $index_right);
}


####
sub map_trace_regions_to_alignments {
	my ($trace_aref, $alignments_aref) = @_;

	my @trace_regions;

	my $region_index = $trace_aref->[0]->{seqIndex};
	my $region_start = $trace_aref->[0]->{colIndex};
	
	for (my $i = 1; $i <= $#$trace_aref; $i++) {
		
		my $next_region_index = $trace_aref->[$i]->{seqIndex};
		if ($next_region_index != $region_index) {
			## add trace region
			my $col_index = $trace_aref->[$i]->{colIndex};
			push (@trace_regions, [$region_start, $col_index-1, $region_index]);
			$region_index = $trace_aref->[$i]->{seqIndex};
			$region_start = $col_index;
		}
	}
	
	# get last one
	push (@trace_regions, [$region_start, $trace_aref->[$#$trace_aref]->{colIndex}, $region_index]);
	

	return(@trace_regions);
}

####
sub build_error_profile {
	my ($other_align_chars_aref, $region_align_chars_aref) = @_;

	my @ret_other_align_chars;
	my @ret_error_profile;

	for (my $i = 0; $i <= $#$other_align_chars_aref; $i++) {
		if ($other_align_chars_aref->[$i]->{char} eq $region_align_chars_aref->[$i]->{char}) {
			push (@ret_other_align_chars, uc $other_align_chars_aref->[$i]->{char});
			push (@ret_error_profile, " ");
		}
		else {
			push (@ret_other_align_chars, lc $other_align_chars_aref->[$i]->{char});
			push (@ret_error_profile, "!");
		}
	}
	
	return(\@ret_other_align_chars, \@ret_error_profile);
}

####
sub find_mult_alignment_inner_bounds {
	my @alignments = @_;

	my @lends;
	my @rends;
	
	foreach my $alignment (@alignments) {
		my ($lend, $rend) = &find_ends_of_alignment($alignment);
		print $alignment->{acc} . " has inner bounds: " . "$lend-$rend\n" if $VERBOSE;
		
		push (@lends, $lend);
		push (@rends, $rend);
	}
	
	

	my $lend_inner_bound = max(@lends);
	my $rend_inner_bound = min(@rends);
	
	return($lend_inner_bound, $rend_inner_bound);
}


####
sub construct_chimera_sequence {
	my ($trace_regions_aref, $alignments_aref) = @_;

	my $chimera_seq = "";
	# print Dumper($trace_regions_aref);
	foreach my $trace_region (@$trace_regions_aref) {
		my ($region_start, $region_end, $seqIndex) = @$trace_region;
		$chimera_seq .= &get_sequence_from_alignment_in_range($alignments_aref->[$seqIndex], $region_start, $region_end); #   join("", @{$alignments_aref->[$seqIndex]->{align}}[$region_start..$region_end]);
	}
	
	return($chimera_seq);
}

####
sub compute_perID {
	my ($alignA, $alignB) = @_;
	
	return(&AlignCompare::compute_per_ID($alignA, $alignB));
}



####
sub apply_min_query_coverage_filter {
	my ($queryAlignStruct, $compareMalignments_aref, $minQueryCoverage) = @_;

	my @ret_alignments;

	my $query_acc = $queryAlignStruct->{acc};
	
	foreach my $alignment (@$compareMalignments_aref) {
		
		my $percent_query_aligned_bases = &compute_percent_query_aligned_bases($queryAlignStruct, $alignment);
		
		my $acc = $alignment->{acc};

		if ($VERBOSE) {
			print "Percent alignment coverage($query_acc, $acc) = " . sprintf("%.2f", $percent_query_aligned_bases) . "\n";
			
		}
		
		if ($percent_query_aligned_bases > $minQueryCoverage) {
			push (@ret_alignments, $alignment);
		}
	}

	return(@ret_alignments);
}

####
sub compute_percent_query_aligned_bases {
	my ($query_alignment, $other_alignment) = @_;
	
	my @query_chars = @{$query_alignment->{align}};
	
	my @other_chars = @{$other_alignment->{align}};

	my $num_pos = 0;
	my $num_aligned = 0;
	
	for (my $i = 0; $i <= $#query_chars; $i++) {
		
		if ($query_chars[$i]->{char} =~ /\w/) {
			$num_pos++;
			
			if ($other_chars[$i]->{char} =~ /\w/) {
				$num_aligned++;
			}
		}
	}

	return($num_aligned/$num_pos * 100);
}

####
sub print_alignments {
	my (@alignments) = @_;

	foreach my $alignment (@alignments) {
		print ">" . $alignment->{acc} . "\n";
		print &get_sequence_from_alignment($alignment) . "\n\n";
	}

	return;
}

sub get_sequence_from_alignment {
	my ($alignment) = @_;
	
	my @char_structs = @{$alignment->{align}};

	my $seq = "";
	foreach my $char_struct (@char_structs) {
		$seq .= $char_struct->{char};
	}

	return($seq);
}

####
sub get_sequence_from_alignment_in_range {
	my ($alignment_obj, $lend, $rend) = @_;

	my $seq = &get_sequence_from_alignment($alignment_obj);

	my $region_seq = substr($seq, $lend, $rend - $lend + 1);

	return($region_seq);
}

####
sub compute_chimera_penalty {
	my ($queryAlignStruct, $minDivR) = @_;

	my $seq = &get_sequence_from_alignment($queryAlignStruct);
	
	my $num_bases = 0;
	while ($seq =~ /[gatc]/gi) {
		$num_bases++;
	}

	my $num_allowable_mismatches = ( (1 - 1/$minDivR) * $num_bases);
	
	# a breakpoint should yield fewer mismatches than this number with respect to the best parent sequence.
	
	my $breakpoint_penalty = int($num_allowable_mismatches + 1) * $MISMATCH_PENALTY;
											 
	return($breakpoint_penalty);
}


####
sub remove_entries_from_alignment_list {
	my ($malignments_aref, $accs_remove_href) = @_;

	my @retMalignments;
	foreach my $malignment (@$malignments_aref) {
		
		unless ($accs_remove_href->{ $malignment->{acc} }) {
			push (@retMalignments, $malignment);
		}
	}
	
	return(@retMalignments);
}

####
sub filter_for_query_alignment_positions {
	my ($queryAlignStruct, $other_alignment_struct) = @_;

	my %pos_want;
	my @query_align = @{$queryAlignStruct->{align}};

	foreach my $query_align_pos (@query_align) {
		$pos_want{$query_align_pos->{pos}} = 1;
	}
	
	my @want_other_align;
	
	my @other_pos = @{$other_alignment_struct->{align}};
	foreach my $other_pos (@other_pos) {
		if ($pos_want{$other_pos->{pos}}) {
			push (@want_other_align, $other_pos);
		}
	}

	my $new_other_alignment_struct = { acc => $other_alignment_struct->{acc},
									   align => \@want_other_align,
	};

	return($new_other_alignment_struct);
}

