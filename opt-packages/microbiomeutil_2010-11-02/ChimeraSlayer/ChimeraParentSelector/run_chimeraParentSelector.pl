#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long qw(:config no_ignore_case bundling);
use FindBin;

use lib ("$FindBin::Bin/../PerlLib");
use Fasta_reader;
use CdbTools;


my $usage = <<_EOUSAGE_;

##########################################################################################
run_CM.pl
##########################################################################################
#
#  Required:
#
#    --query_NAST      multi-fasta file containing query sequences in alignment format
#
#    --db_NAST        db in NAST format
#    --db_FASTA       db in fasta format (megablast formatted)
#
#  Common opts:
#
#    -n       number of top matching database sequences to compare to (default 15)
#    -R       min divergence ratio default: 1.007
#    -P       min percent identity among matching sequences (default 90)
#
#  ## parameters to tune ChimeraParentSelector:
#   
#  Scoring parameters:
#   -M match score   (default: +5)
#   -N mismatch penalty  (default: -4)
#   -Q min query coverage by matching database sequence (default: 70)
#   -T maximum traverses of the multiple alignment  (default: 1)
#
#
#  Flags:
#   --printAlignments     (default off)
#   -v   verbose
#
#########################################################################################


_EOUSAGE_
	
	;


## required options
my ($query_NAST, $db_NAST, $db_FASTA);

# common opts
my $numSeqsCompare = 15;
my $minPerID = 90;
my $minDivR = 1.007;

# chimera maligner opts:
my ($matchScore, $mismatchPenalty, $maxTraverse, $minQueryCoverage);
my $VERBOSE;
my $DEBUG;

# misc
my $printAlignmentsFlag = 0;

my $TMP = $ENV{TMPDIR} || "/tmp";

&GetOptions (
	
			 "query_NAST=s" => \$query_NAST,
			 "db_NAST=s" => \$db_NAST,
			 "db_FASTA=s" => \$db_FASTA,
			 
			 # common opts
			 "R=f" => \$minDivR,  # same as -R on chimeraParentSelector
			 "n=i" => \$numSeqsCompare,
			 "P=f" => \$minPerID,
			 
			 ## ChimeraParentSelector parameters:
			 "M=i" => \$matchScore,
			 "N=i" => \$mismatchPenalty,
			 "Q=i" => \$minQueryCoverage,
			 "T=i" => \$maxTraverse,	
			 
			 "printAlignments" => \$printAlignmentsFlag,
			 'v' => \$VERBOSE,
			 'DEBUG' => \$DEBUG,
	);

unless ($query_NAST && $db_NAST && $db_FASTA) { die $usage; }

my $num_blast_hits = $numSeqsCompare + 1; # include self potentially.

main: {
	
	my $fasta_reader = new Fasta_reader($query_NAST);
	while (my $seq_obj = $fasta_reader->next()) {
		my $acc = $seq_obj->get_accession();
		my $seqlength = length($seq_obj->get_sequence());
		if ($seqlength == 0) {
			print "!!! ERROR, $acc has no NAST sequence.  Skipping.\n";
			print STDERR "!!! ERROR, $acc has no NAST sequence.  Skipping.\n";
			next;
		}
				
		print "\nQuery: $acc\n\n" if $VERBOSE;
		
		my $fasta_format = $seq_obj->get_FASTA_format();
		my $query_sequence = $seq_obj->get_sequence();
		$query_sequence =~ s/[\.\-]//g; # strip gaps if in fasta-align format.

		my $query_file = "$TMP/tmp.$$.query";
		my $db_file = "$TMP/tmp.$$.db";
		open (my $fh, ">$query_file") or die "Error, cannot write to $query_file ";
		print $fh $fasta_format;
		close $fh;
		
		# run megablast, get top hits
		my $top_hits = &blast_to_top_hits($acc, $query_sequence, $db_FASTA);
		
		
		unless ($top_hits) {
			print "ChimeraParentSelector\t$acc\tUNKNOWN\n";
			next;
		}
		
		print "Selected Top Hits:\t$top_hits\n" if $VERBOSE;
		

		open ($fh, ">$db_file") or die "Error, cannot write to $db_file";
		foreach my $hit_acc (split (/\s+/, $top_hits)) {
			my $nast = &cdbyank($hit_acc, $db_NAST);
			print $fh $nast;
		}
		close $fh;
		
		eval {
			## run chimeraMaligner
			my $cmd = "$FindBin::Bin/chimeraParentSelector.pl --query_NAST $query_file --db_NAST $db_file ";
			
			if ($printAlignmentsFlag) {
			    $cmd .= " --printAlignments ";
			}
						
			if (defined $matchScore) {
				$cmd .= " -M $matchScore ";
			}
			if (defined $mismatchPenalty) {
				$cmd .= " -N $mismatchPenalty ";
			}
			if (defined $minDivR) {
				$cmd .= " -R $minDivR ";
			}
			if (defined $maxTraverse) {
				$cmd .= " -T $maxTraverse ";
			}
			if (defined $minQueryCoverage) {
				$cmd .= " -Q $minQueryCoverage ";
			}
			
			print STDERR "$cmd\n";
			my $ret = system $cmd;
			if ($ret) {
				die "Error, cmd: $cmd died with ret ($ret)";
			}
		};
		if ($@) {
			print STDERR "$acc failed:   $@\n\n";
			die;
		}
		
		unlink($query_file, $db_file) unless $DEBUG;

	}
	
	exit(0);
}

####
sub blast_to_top_hits {
	my ($acc, $query_seq, $db_FASTA) = @_;

	my $length = length($query_seq);
	
	## search first 33% and last 33% of sequence.
	
	my $first_part = substr($query_seq, 0, int(0.33 * $length));
	
	my $second_part = substr($query_seq, int(0.66 * $length));
	
	my @top_hits_first = &blast_seq($acc, $first_part, $db_FASTA);
	my @top_hits_second = &blast_seq($acc, $second_part, $db_FASTA);
	
	print "Top hits Left:\n" . join ("\t\n", @top_hits_first) . "\n\n" if $VERBOSE;
	
	print "Top hits Right:\n" . join ("\t\n", @top_hits_second) . "\n\n" if $VERBOSE;


	my @merged_hits = &merge_hits(\@top_hits_first, \@top_hits_second);
	
	
	# Use full union N-number of best hits from each side.
	
	#if (scalar(@merged_hits) > $numSeqsCompare) {
	#	@merged_hits = @merged_hits[0..$numSeqsCompare-1];
	#}
	
	return (join (" ", @merged_hits));	
}


####
sub merge_hits {
	my ($list_A_aref, $list_B_aref) = @_;
	
	my @A = @$list_A_aref;
	my @B = @$list_B_aref;
	
	my %seen;
	my @merged;
	while (@A || @B) {
		if (@A) {
			my $entry = shift @A;
			if (! $seen{$entry}) {
				push (@merged, $entry);
				$seen{$entry} = 1;
			}
		}
		if (@B) {
			my $entry = shift @B;
			if (! $seen{$entry}) {
				push (@merged, $entry);
				$seen{$entry} = 1;
			}
		}
	}
	
	return(@merged);
}
	
####
sub blast_seq {
	my ($acc, $seq, $db) = @_;

	my $tmpfile = "$TMP/tmp.$$.q";

	open (my $fh, ">$tmpfile") or die $!;
	print $fh ">$acc\n$seq\n";
	close $fh;
	
	my $cmd = "megablast -d $db -i $tmpfile -e 1e-10 -m 8 -v $num_blast_hits -b $num_blast_hits 2>/dev/null";
		
	my @results = `$cmd`;
	
	unlink($tmpfile);
	
	if ($?) {
	    print STDERR "Error, cmd $cmd died with ret $?";
		return(); # empty blast results.
	}

	my @top_hits;
	my %seen;
	foreach my $result (@results) {
		my @x = split (/\t/, $result);
		
		$x[1] =~ s/\#.*$//;  # megablast bundling space-delimited header components into \#-delimited accessions. weird stuff...

		if ($x[0] eq $x[1]) { next; } # no same query as hit.
		my $acc = $x[1];
		
		my $per_ID = $x[11];

		unless ($per_ID >= $minPerID) { next; }
		
		if (! $seen{$acc}) {
			$seen{$acc} = 1;
			push (@top_hits, $acc);
		}
	}

	return(@top_hits);
}

