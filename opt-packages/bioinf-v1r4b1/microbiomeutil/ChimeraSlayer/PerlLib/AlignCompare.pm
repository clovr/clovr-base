package AlignCompare;

use strict;
use warnings;
use Carp qw (cluck confess);
use List::Util qw (min max);


## In all methods below, non-GATC characters do not count as valid bases ##


sub compute_per_ID {
	my ($seqA, $seqB) = @_;


	if (length($seqA) != length($seqB)) {
		confess "Error, cannot compute perID for nonidentical sequence lengths";
	}
	
	my @charsA = split(//, uc $seqA);
	my @charsB = split(//, uc $seqB);
        
	
	my ($lendBoundA, $rendBoundA) = &find_ends_of_alignment(@charsA);
	my ($lendBoundB, $rendBoundB) = &find_ends_of_alignment(@charsB);

	my $lend_bound = max($lendBoundA, $lendBoundB);
	my $rend_bound = min($rendBoundA, $rendBoundB);
	

	my $same_chars = 0;
	my $chars_in_A = 0;
	my $chars_in_B = 0;
	

	for (my $i = $lend_bound; $i <= $rend_bound; $i++) {
		my $charA = $charsA[$i];
		my $charB = $charsB[$i];
		
		## If character is not recognized, it's completely ignored.
		if ($charA !~ /[GATC\.\-]/i || $charB !~ /[GATC\.\-]/i ) { next; }
		
		my $charA_GATC = ($charA =~ /[GATC]/) ? 1:0;
		my $charB_GATC = ($charB =~ /[GATC]/) ? 1:0;
		
		if ($charA_GATC || $charB_GATC)  {
						
			if ($charA_GATC) {
				$chars_in_A++;
			}
			if ($charB_GATC) {
				$chars_in_B++;
			}
			
			if ($charA eq $charB) {
				$same_chars++;
			}
		}
	}
	
	## total number of chars in alignment is taken as the average of the two sequence lengths.
	my $num_chars = ($chars_in_A + $chars_in_B) / 2;

	if ($num_chars == 0) {
	    cluck "Warning, no base characters in either A or B sequences";
		return(0);
	}
	
	return($same_chars/$num_chars * 100);
	
}

####
sub find_lend_match {
	my ($charsA_aref, $charsB_aref) = @_;

	for (my $i = 0; $i <= $#$charsA_aref; $i++) {
		if ($charsA_aref->[$i] =~ /[GATC]/i && $charsB_aref->[$i] =~ /[GATC]/i) {
			return($i);
		}
	}
        
	return(0);  # default is start at beginning
}

####
sub find_rend_match {
	my ($charsA_aref, $charsB_aref) = @_;

	for (my $i = $#$charsA_aref; $i >= 0; $i--) {
		if ($charsA_aref->[$i] =~ /[GATC]/i && $charsB_aref->[$i] =~ /[GATC]/i) {
			return($i);
		}
	}
        
	return($#$charsA_aref);  # default is stop at end
}

####
sub define_left_clip {
	my ($chars_aref, $start, $length) = @_;
	
	my $count = 0;
	for (my $i = $start; $i >= 0; $i--) {
		my $char = $chars_aref->[$i];
		if ($char =~ /\w/) {
			$count++;
			if ($count >= $length) {
				return($i);
			}
		}
	}
	
	confess "Error, couldn't define a left clip position";
}

####
sub define_right_clip {
	my ($chars_aref, $start, $length) = @_;

	my $count = 0;
	for (my $j = $start; $j <= $#$chars_aref; $j++) {
		my $char = $chars_aref->[$j];
		if ($char =~ /\w/i) {
			$count++;
			if ($count >= $length) {
				return($j);
			}
		}
	}
	
	confess ("Error, cannot define a right clip position");
}



####
sub find_ends_of_alignment {
	my @align_array = @_;
		
	my $index_left;
	my $index_right;

	for (my $i = 0; $i <= $#align_array; $i++) {
		if ($align_array[$i] =~ /[GATC]/i) {
			$index_left = $i;
			last;
		}
	}

	for (my $i = $#align_array; $i >= 0; $i--) {
		if ($align_array[$i] =~ /[GATC]/i) {
			$index_right = $i;
			last;
		}
	}
	
	return($index_left, $index_right);
}



1; #EOM
