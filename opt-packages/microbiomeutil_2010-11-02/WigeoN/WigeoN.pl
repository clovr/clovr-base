#!/usr/bin/env perl

use strict;
use warnings;

use Carp;
use Getopt::Long qw(:config no_ignore_case bundling);
use FindBin;
use POSIX;

use lib ("$FindBin::Bin/PerlLib");
use Fasta_reader;
use BHStats;

my $usage = <<_EOUSAGE_;

###############################################################################
#
#  -Q        query sequence (NAST alignment format)
#  -R        reference sequence (NAST alignment format)
#  -P        reference conservation profile
#
#  -M        position mask
#
#  -W          window size (default: 300)
#  -S          step size   (default: 25)
#
#  --plot     plot observed vs. expected values
#
#  --DEBUG    sequences analyzed are written to file \$pid.ref and \$pid.qry
#
###############################################################################

_EOUSAGE_

	;


my $help_flag;
my $win_size = 300;
my $step_size = 25;


my $MIN_RANGE_LEND = 0; 
my $MAX_RANGE_REND = 9999999; 


my $plotDataFlag = 0;
my ($profileFile, $queryAlignFile, $referenceAlignFile);
my $positionMaskFile = undef;

my $DEBUG = 0;

&GetOptions ( 'h' => \$help_flag,
			  'W=i' => \$win_size,
			  'S=i' => \$step_size,
			  'P=s' => \$profileFile,
			  'Q=s' => \$queryAlignFile,
			  'R=s' => \$referenceAlignFile,
			  'plot' => \$plotDataFlag,
			  'M=s' => \$positionMaskFile,
			  'DEBUG' => \$DEBUG,
	);


if ( $help_flag || ! ($queryAlignFile && $referenceAlignFile && $profileFile) ) {
	die $usage;
}


main: {
	
	################################
	#### Prepare inputs for analysis

	my %quantiles = &getQuantiles();
	
	my @positionMask;
	if ($positionMaskFile) {
		@positionMask = &get_position_mask($positionMaskFile);
	}
		
	my ($queryAcc, $queryAlignString) = &retrieve_sequence_from_file($queryAlignFile);
			
	my ($refAcc, $referenceAlignString) = &retrieve_sequence_from_file($referenceAlignFile);
	
	&update_position_mask_by_Ns($queryAlignString, $referenceAlignString, \@positionMask);
	

	my @query_relevant_positions = &extract_relevant_positions($queryAlignString, \@positionMask); # only alignment positions corresponding to the eco ref sequence.
	my @reference_relevant_positions = &extract_relevant_positions($referenceAlignString, \@positionMask);
	
	#print "Ref_rel: " . join (" ", @reference_relevant_positions) . "\n";
	
	## determine range of aligned sequence pairs:
	my ($lend, $rend) = &determine_alignment_span(\@query_relevant_positions, \@reference_relevant_positions);

	my @conservation_profile = &get_conservation_profile($profileFile, \@positionMask);	
	
	unless ($lend < $rend) {

		die "Error, alignment range: $lend-$rend is invalid";
	}
	
	if ($lend < $MIN_RANGE_LEND) {
		$lend = $MIN_RANGE_LEND;
	}
	if ($rend > $MAX_RANGE_REND) {
		$rend = $MAX_RANGE_REND;
	}
	
	if ($rend - $lend + 1 < $win_size + $step_size) {
		print "$queryAcc\t$refAcc\tdiv:\tNA\tstDev: NA\tNA\n";
		die "Error, alignment between query and reference spans $lend-$rend and less than win_size: $win_size";
	}
		
	#######################################
	#######  Start the Pintail operations:

	## analyze query and reference sequences.
	
	my $percent_divergence = &compute_sequence_divergence(\@query_relevant_positions, \@reference_relevant_positions,
														  $lend, $rend);
	
	my @Oqs = &compute_windowed_percent_mismatches(\@query_relevant_positions, \@reference_relevant_positions,
												   $lend, $rend,
												   $win_size, $step_size);
	
	
	my $mean_observed_percentage_differences = &BHStats::avg(@Oqs);


	## analyze the given divergence profile to compute expected variation
	
	my @divergence_profile = &compute_divergence_profile(@conservation_profile);
	#print STDERR "Divergence_profile: @divergence_profile\n\n";
	
	

	my @average_divergence_profile = &compute_windowed_average_divergence(\@divergence_profile, $lend, $rend, $win_size, $step_size);
	# print STDERR "Avg_divergence_profile: @average_divergence_profile\n\n";

	my $mean_avg_divergence = &BHStats::avg(@average_divergence_profile);
	
	my $scaling_factor = 1;
	if ($mean_avg_divergence > 0) {
		$scaling_factor = $mean_observed_percentage_differences / $mean_avg_divergence;
	}
	
	my @Eqs = &scale_average_divergences(\@average_divergence_profile, $scaling_factor);
	# print STDERR "Scaled_avg_divergences: @Eqs\n";
	my $mean_expected_divergence = &BHStats::avg(@Eqs);

	## plot Eqs vs. Oqs
	if ($plotDataFlag) {
		&plot_data(\@Oqs, \@Eqs, $queryAcc);
	}
	
	
	## compute deviation from expected value:
	my $stDev = &compute_deviation_from_expectation(\@Oqs, \@Eqs);
	
	## format outputs
	$stDev = sprintf("%.2f", $stDev);
	$percent_divergence = sprintf("%.2f", $percent_divergence * 100);
	
	
	####
	# compute Quantiles based on Mallard published formulas:
	# my $Q95 = sprintf("%.3f", 2.64*log($mean_observed_percentage_differences)/log(10)  + 1.46); (doesn't really work well...)
	
	my $perDiv = int($percent_divergence+0.5);

	my $Q95 = $quantiles{$perDiv}->{"0.95"};
	my $Q99 = $quantiles{$perDiv}->{"0.99"};
	my $Q999 = $quantiles{$perDiv}->{"0.999"};
	my $Q9999 = $quantiles{$perDiv}->{"0.9999"};
	
	my $chimera_flag_95 = ($perDiv > 0 && $stDev > $Q95) ? "Yes" : "No";
	my $chimera_flag_99 = ($perDiv > 0 && $stDev > $Q99) ? "YES" : "No";
	my $chimera_flag_999 = ($perDiv > 0 && $stDev > $Q999) ? "YES" : "No";
	my $chimera_flag_9999 = ($perDiv > 0 && $stDev > $Q9999) ? "YES" : "No";

	print "$queryAcc\t$refAcc\tdiv:\t$percent_divergence\tstDev:\t$stDev\t"
	  . "Quant95:$chimera_flag_95\t"
	  . "Quant99:$chimera_flag_99\t"
	  . "Quant99.9:$chimera_flag_999\t"
	  . "Quant99.99:$chimera_flag_9999\n";
	
	
	exit(0);
}

####
sub retrieve_sequence_from_file {
	my ($fastaFile) = @_;

	my $fasta_reader = new Fasta_reader($fastaFile);
	my $seq_obj = $fasta_reader->next();

	my $accession = $seq_obj->get_accession();
	my $sequence = uc $seq_obj->get_sequence();

	return($accession, $sequence);
}


####
sub get_position_mask {
	my ($maskFile) = @_;
		
	my $fasta_reader = new Fasta_reader($maskFile);
	my $seq_obj = $fasta_reader->next();
	my $seq = $seq_obj->get_sequence();
    my @pos_mask = split (//, $seq);

	return(@pos_mask);
}

####
sub extract_relevant_positions {
	my ($alignString, $positionMask_aref) = @_;

	my @align_chars = split (//, uc $alignString);
	
	if (@$positionMask_aref) {
		my @relevant_positions;
		
		for (my $i = 0; $i <= $#align_chars; $i++) {
			if ($positionMask_aref->[$i] ne '0' && $positionMask_aref->[$i] =~ /\w/) {
				push (@relevant_positions, $align_chars[$i]);
			}
		}
		
		return(@relevant_positions);
	}
	else {
		return(@align_chars);
	}
}


####
sub determine_alignment_span {
	my ($alignA_aref, $alignB_aref) = @_;

	my $lend = undef;
	my $rend = undef;

	my $alignment_length = scalar (@$alignA_aref);

	## walk from left to first aligned positions:
	for (my $i = 0; $i < $alignment_length; $i++) {
		if ($alignA_aref->[$i] =~ /\w/ && $alignB_aref->[$i] =~ /\w/) {
			$lend = $i;
			last;
		}
	}

	## walk from right to first aligned positions:
	for (my $i = $alignment_length-1; $i >= 0; $i--) {
		if ($alignA_aref->[$i] =~ /\w/ && $alignB_aref->[$i] =~ /\w/) {
			$rend = $i;
			last;
		}
	}
	
	unless (defined $lend && defined $rend) {
		confess "Error, no aligned positions found between query and reference";
	}

	return ($lend, $rend);
}

####
sub get_conservation_profile {
	my ($profileFile, $positionMask_aref) = @_;
	
	my @cons_profile;

	open (my $fh, $profileFile) or die "Error, cannot open profile file $profileFile";
	while (<$fh>) {
		chomp;
		my ($position, $val) = split (/\t/);
		if (@$positionMask_aref) {
			if ($positionMask_aref->[$position] ne '0' && $positionMask_aref->[$position] =~ /\w/) { 
				push (@cons_profile, $val);
			}
		}
		else {
			# all vals considered:
			push (@cons_profile, $val);
		}
	}
	close $fh;
	
	return(@cons_profile);
}

####
sub compute_windowed_percent_mismatches {
	my ($query_aref, $reference_aref, $lend, $rend, $win_size, $step_size) = @_;


	my @mismatch_window_profile;

	for (my $i = $lend; $i <= $rend - $win_size + 1; $i+= $step_size) {
		
		my $num_mismatches = 0;
		for (my $j = $i; $j <= $i+$win_size - 1; $j++) {
			if ( ($query_aref->[$j] ne $reference_aref->[$j]) 
				 && 
				 ($query_aref->[$j] =~ /\w/ || $reference_aref->[$j] =~ /\w/) ) {
				$num_mismatches++;
			}
		}
		my $percent_mismatches = $num_mismatches / $win_size * 100;
	
		push (@mismatch_window_profile, $percent_mismatches);
	}
	
	return (@mismatch_window_profile);
}

####
sub compute_sequence_divergence {
	my ($query_aref, $reference_aref, $lend, $rend) = @_;
	
	if ($DEBUG) {
		open (my $ofh, ">$$.qry") or die "Error, cannot write $$.qry";
		print $ofh ">qry\n" . join("", @$query_aref) . "\n";
		close $ofh;

		open ($ofh, ">$$.ref") or die "Error, cannot write $$.ref";
		print $ofh ">ref\n" . join("", @$reference_aref) . "\n";
		close $ofh;
	}
	

	my $num_mismatches = 0;
	my $total_pos = 0;
	for (my $i = $lend; $i <= $rend; $i++) {
		if ($query_aref->[$i] =~ /\w/ || $reference_aref->[$i] =~ /\w/)  {
			$total_pos++;
			
			if ($query_aref->[$i] ne $reference_aref->[$i]) {
				$num_mismatches++;
			}
		}
	}
	
	my $divergence = $num_mismatches / $total_pos;
	return($divergence);
}


####
sub compute_divergence_profile {
	my (@conservation_profile) = @_;

	my @divergence_profile;
	
	foreach my $val (@conservation_profile) {
		
		## convert to a probability as per Pintail style
		my $pval = ($val - 0.25) / 0.75;
		#my $pval = $val;
		
		if ($pval < 0) {
			$pval = 0; # cannot have negative probabilty values.
		}

		my $qval = 1 - $pval;
		push (@divergence_profile, $qval);
	}
	
	return (@divergence_profile);
}

####
sub compute_windowed_average_divergence {
	my ($divergence_profile_aref, $lend, $rend, $win_size, $step_size) = @_;
	
	# print STDERR "params: @_\n";
	
	my @window_avgs;

	# print STDERR "lend=$lend, rend=$rend\n";
	for (my $i = $lend; $i <= $rend - $win_size + 1; $i+= $step_size) {
		
		my $avg = &BHStats::avg(@$divergence_profile_aref[$i..($i+$win_size-1)]);
		push (@window_avgs, $avg);
		# print STDERR "$i: $avg\n";
	}

	return (@window_avgs);
}


####
sub scale_average_divergences {
	my ($avg_divergence_profile_aref, $scaling_factor) = @_;

	my @scaled_values;
	
	foreach my $val (@$avg_divergence_profile_aref) {
		push (@scaled_values, $val * $scaling_factor);
	}

	return (@scaled_values);
}


####
sub compute_deviation_from_expectation {
	my ($Oqs_aref, $Eqs_aref) = @_;

	my $sum_diff = 0;
	
	my $num_vals = scalar(@$Oqs_aref);
	if (scalar (@$Eqs_aref) != $num_vals) {
		confess "Error, different numbers of windows are reported for Oqs and Eqs! ";
	}
	
	for (my $i = 0; $i < $num_vals; $i++) {
		my $o_val = $Oqs_aref->[$i];
		my $e_val = $Eqs_aref->[$i];
		
		$sum_diff += ($o_val - $e_val) ** 2;
	}
	
	$sum_diff /= ($num_vals - 1);
	
	my $DE = $sum_diff ** 0.5; # sqrt
	
	return ($DE);
}


####
sub plot_data {
	my ($Oqs_aref, $Eqs_aref, $basefilename) = @_;

	$basefilename =~ s/\W/_/g;
	
	# write Oqs and Eqs vals
	{
		open (my $fh, ">OEqs.dat") or die "Error, cannot write to Oqs.dat";
		for (my $i = 0; $i <= $#$Oqs_aref; $i++) {
			my $pos = $i * $step_size;
			print $fh "$pos\t" . $Oqs_aref->[$i] . "\t" . $Eqs_aref->[$i] . "\n";
		}
		close $fh;
	}
	
	# write a gnuplot script
	open (my $fh, ">gnuplot.script") or die "Error, cannot write to gnuplot.script";
	print $fh "set term png color\n";
	print $fh "set output \'W.$basefilename.png\'\n";
	print $fh "plot \'OEqs.dat\' using 1:2 t \'Observed\' w lp, \'OEqs.dat\' using 1:3 t \'Expected\' w lp\n";
	close $fh;
	
	system("gnuplot gnuplot.script");
	
	return;
}


####
sub compute_max_delta {
	my ($vals_aref, $point) = @_;

	my @deltas;
	
	foreach my $val (@$vals_aref) {
		my $delta = abs($val - $point);
		push (@deltas, $delta);
	}

	@deltas = sort {$a<=>$b} @deltas;

	my $max_delta = pop @deltas;
	
	return($max_delta);
}


####
sub compute_max_DOE { # max diff between observed and expected value
	my ($Oqs_aref, $Eqs_aref) = @_;
	
	
	my @deltas;
	
	my $num_vals = scalar(@$Oqs_aref);
	if (scalar (@$Eqs_aref) != $num_vals) {
		confess "Error, different numbers of windows are reported for Oqs and Eqs! ";
	}
	
	for (my $i = 0; $i < $num_vals; $i++) {
		my $o_val = $Oqs_aref->[$i];
		my $e_val = $Eqs_aref->[$i];
		
		my $delta = abs ($o_val - $e_val);
		push (@deltas, $delta);
	}
	
	@deltas = sort {$a<=>$b} @deltas;

	my $max_delta = pop @deltas;

	return($max_delta);
	
}

####
sub update_position_mask_by_Ns {
	my ($seqA, $seqB, $positionMask_aref) = @_;

	my @A_chars = split (//, $seqA);
	my @B_chars = split (//, $seqB);
	
	if (scalar(@A_chars) != scalar(@B_chars)) {
		die "Error, query and reference sequences have different lengths";
	}
	
	for (my $i = 0; $i <= $#A_chars; $i++) {
		if ($A_chars[$i] =~/n/i
			||
			$B_chars[$i] =~/n/i
			) {
			$positionMask_aref->[$i] = '0'; # masking position that contains a 'n' character
		}
	}

	## Mask gaps neighboring N's in the query sequence
	for (my $i = 0; $i <= $#A_chars; $i++) {
		if ($A_chars[$i] =~/n/i) {
			for (my $j = $i - 1; $j >0 && $A_chars[$j] =~ /[\-\.]/; $j--) {
				$positionMask_aref->[$j] = '0'; # masking position that contains a 'n' character
			}
		}
	}
	
	return;
}

sub getQuantiles {

#Div	NumDataPts	0.5	0.75	0.9	0.95	0.99	0.999	0.9999

	my @divs = qw (0.5	0.75	0.9	0.95	0.99	0.999	0.9999);

## New data from a comprehensive comparison

	my $quantiles = <<__EOQUANTILES;

1	5971		0.94	1.19	1.43	1.58	1.92	2.31	2.66
2	11687		1.21	1.46	1.73	1.89	2.27	3.08	3.26
3	16021		1.43	1.75	2.10	2.39	3.00	3.36	3.69
4	15122		1.65	2.01	2.45	2.71	3.12	3.46	3.73
5	14077		1.75	2.12	2.52	2.81	3.43	4.35	4.82
6	16820		1.89	2.34	2.78	3.11	3.69	4.41	4.77
7	25280		2.03	2.51	2.98	3.29	3.89	4.63	5.31
8	29796		2.28	2.76	3.18	3.45	4.05	5.00	5.65
9	51727		2.50	3.09	3.55	3.79	4.25	5.06	5.89
10	91244		2.53	3.12	3.57	3.82	4.30	4.94	5.48
11	150480		2.57	3.11	3.62	3.89	4.31	4.83	5.37
12	192707		2.56	3.10	3.65	3.95	4.46	5.53	6.44
13	201523		2.51	3.04	3.59	3.97	4.93	6.10	6.77
14	192846		2.49	3.00	3.62	4.13	5.32	6.24	6.75
15	172994		2.51	3.06	3.82	4.49	5.57	6.33	6.77
16	158844		2.60	3.23	4.02	4.69	5.62	6.33	6.88
17	155158		2.69	3.27	4.01	4.68	5.65	6.49	7.14
18	165720		2.67	3.22	3.89	4.42	5.51	6.36	7.09
19	208108		2.57	3.19	3.91	4.42	5.50	6.69	7.45
20	301424		2.59	3.34	4.15	4.63	5.55	6.93	7.84
21	540297		2.65	3.43	4.25	4.67	5.46	6.77	7.87
22	926699		2.67	3.47	4.31	4.75	5.53	6.55	7.88
23	1374655		2.63	3.43	4.32	4.85	5.79	6.94	7.70
24	1636025		2.58	3.38	4.39	5.04	6.14	7.13	7.71
25	1594071		2.52	3.34	4.36	5.11	6.27	7.13	7.71
26	1351164		2.56	3.39	4.37	5.07	6.26	7.20	8.06
27	1102752		2.77	3.59	4.43	4.98	6.06	7.05	8.62
28	961056		3.04	3.77	4.45	4.87	5.76	6.90	8.58
29	760581		3.22	3.92	4.56	4.97	5.90	7.35	8.57
30	457388		3.38	4.10	4.78	5.22	6.23	7.60	8.48


__EOQUANTILES



## OLD data	
#	my @divs = qw (0.1 0.25 0.5 0.75 0.95 0.99);
	
#div    0.1     0.25    0.5     0.75   0.95     0.99   # quantiles	
#	my $quantiles = <<__EOQUANTILES;
#1       0.24    0.38    0.55    0.73    1.17    1.41
#2       0.62    0.75    0.95    1.19    1.58    1.83
#3       0.83    1       1.2     1.43    1.88    2.29
#4       1.04    1.24    1.52    1.81    2.28    2.86
#5       1.2     1.44    1.76    2.1     2.83    3.64
#6       1.3     1.59    1.92    2.35    3.828   4.57
#7       1.36    1.63    2.02    2.55    3.8625  4.6025
#8       1.43    1.71    2.1     2.62    3.64    5.17
#9       1.6     1.97    2.48    2.97    3.7     4.3
#10      1.76    2.24    2.83    3.32    3.92    4.31
#11      1.74    2.16    2.7     3.23    3.91    4.37
#12      1.8     2.22    2.7     3.22    3.99    4.45
#13      1.78    2.18    2.67    3.23    4.07    4.66
#14      1.7     2.08    2.54    3.07    3.92    4.88
#15      1.65    2.02    2.5     3.02    4.04    5.1913
#16      1.65    2.02    2.48    3.02    4.22    5.41
#17      1.69    2.06    2.58    3.23    4.51    5.58
#18      1.76    2.15    2.69    3.28    4.54    5.6464
#19      1.77    2.16    2.69    3.29    4.41    5.56
#20      1.72    2.1     2.62    3.27    4.46    5.45
#21      1.69    2.09    2.67    3.52    4.64    5.38
#22      1.61    2.03    2.64    3.53    4.71    5.42
#23      1.6     2.01    2.61    3.47    4.85    5.58
#24      1.57    1.96    2.52    3.32    4.93    5.85
#25      1.53    1.91    2.44    3.18    4.92    6.1
#26      1.54    1.9     2.43    3.2     4.84    6.1
#27      1.58    1.96    2.51    3.3     4.79    5.99
#28      1.7     2.12    2.76    3.55    4.86    5.89
#29      1.91    2.41    3.07    3.79    4.88    5.74
#30      2.11    2.6     3.23    3.91    4.96    5.8
#
#__EOQUANTILES


;

	
	my %quantiles;
	foreach my $quantile_row (split (/\n/, $quantiles)) {
		unless ($quantile_row =~ /\w/) { next; }
		my ($div, $num_pts, @vals) = split (/\s+/, $quantile_row);
		foreach my $d (@divs) {
			my $val = shift @vals;
			unless ($val =~ /\d/) { die "Error parsing val from $quantile_row "; }
			$quantiles{$div}->{$d} = $val;
		}
	}
	
	
	return(%quantiles);
}



	
