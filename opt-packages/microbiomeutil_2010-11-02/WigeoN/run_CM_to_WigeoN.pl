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
#  ## parameters to tune ChimeraMaligner:
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
#   --exec_dir          cd here before running
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

# misc
my $printAlignmentsFlag = 0;
my $exec_dir;

&GetOptions (
	
	"query_NAST=s" => \$query_NAST,
	"db_NAST=s" => \$db_NAST,
	"db_FASTA=s" => \$db_FASTA,
	
	# common opts
	"R=f" => \$minDivR,  # same as -R on chimeraMaligner
	"n=i" => \$numSeqsCompare,
	"P=f" => \$minPerID,
	
	## ChimeraMaligner parameters:
	"M=i" => \$matchScore,
	"N=i" => \$mismatchPenalty,
	"Q=i" => \$minQueryCoverage,
	"T=i" => \$maxTraverse,	
		
	"printAlignments" => \$printAlignmentsFlag,
	'v' => \$VERBOSE,
	
	'exec_dir=s' => \$exec_dir,

	);

unless ($query_NAST && $db_NAST && $db_FASTA) { die $usage; }


chdir($exec_dir) or die "Error, cannot cd to $exec_dir";

my $num_blast_hits = $numSeqsCompare + 1; # include self potentially.

main: {
	
	my $fasta_reader = new Fasta_reader($query_NAST);
	while (my $seq_obj = $fasta_reader->next()) {
		my $acc = $seq_obj->get_accession();
		my $query_acc = $acc; # should make all query_acc here.
		my $seqlength = length($seq_obj->get_sequence());
		my $query_seq = $seq_obj->get_sequence();
		$query_seq =~ s/[\-\.]//g;
		if ($seqlength == 0) {
			print "!!! ERROR, $acc has no NAST sequence.  Skipping.\n";
			print STDERR "!!! ERROR, $acc has no NAST sequence.  Skipping.\n";
			next;
		}
				
		print "\nQuery: $acc\n\n" if $VERBOSE;
		
		my $fasta_format = $seq_obj->get_FASTA_format();
		my $query_sequence = $seq_obj->get_sequence();
		$query_sequence =~ s/[\.\-]//g; # strip gaps if in fasta-align format.

		my $query_file = "tmp.$$.query";
		my $db_file = "tmp.$$.db";
		open (my $fh, ">$query_file") or die "Error, cannot write to $query_file ";
		print $fh $fasta_format;
		close $fh;
		
		my %DB_seqs;

		# run megablast, get single top hits
		#my $best_hit;
		#{
		#my @best_hits = &blast_seq($acc, $query_sequence, $db_FASTA);
		#	$best_hit = shift @best_hits;
		#}
		#my $best_hit_fasta = &cdbyank($best_hit, $db_NAST);
		
		#$DB_seqs{$best_hit} = $best_hit_fasta;

		# run megablast, get hits from each end of seq (2 separate searches)
		my $top_hits = &blast_to_top_hits($acc, $query_sequence, $db_FASTA);
		
		
		unless ($top_hits) {
			print "ChimeraMaligner\t$acc\tUNKNOWN\n";
			next;
		}
		
		print "Selected Top Hits:\t$top_hits\n" if $VERBOSE;
				
		open ($fh, ">$db_file") or die "Error, cannot write to $db_file";
		foreach my $hit_acc (split (/\s+/, $top_hits)) {
			my $nast = &cdbyank($hit_acc, $db_NAST);
			print $fh $nast;
			$DB_seqs{$hit_acc} = $nast;
		}
		close $fh;
		
		eval {
			## run chimeraMaligner
			my $cmd = "$FindBin::Bin/../CMCS/ChimeraMaligner/chimeraMaligner.pl --query_NAST $query_file --db_NAST $db_file ";
			
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
		
			my $result = `$cmd`;
			if ($?) {
				die "Error, cmd $cmd died with ret $?";
			}
			my @toks = split(/\t/, $result);
			my @accs_for_renast;
			if ($toks[2] eq 'YES') {
				while ($toks[3] =~ /\((\S+), NAST:(\d+)-(\d+), ECO:\d+-\d+, RawLen:(\d+), G:([\d\.]+), L:([\d\.]+), ([\d\.]+)\)/g) {
					
					my $acc = $1;
					
					my $range_lend = $2;
					my $range_rend = $3;
					
					my $segmentLength = $4;
					
					my $global_per_id = $5;
					my $local_per_id = $6;
					my $divR = $7;
					
					push (@accs_for_renast, $acc);
				}
			
				## RENAST it!
				open (my $ofh, ">$query_file.tmp") or die $!;
				print $ofh ">$query_acc\n$query_seq\n";
				close $ofh;
				
				open ($ofh, ">$query_file.dbrenast.tmp") or die $!;
				foreach my $acc (@accs_for_renast) {
					my $fasta_seq = $DB_seqs{$acc};
					print $ofh $fasta_seq . "\n";
				}
				close $ofh;

				## RENAST it
				my $cmd = "NAST-iEr $query_file.dbrenast.tmp $query_file.tmp > $query_file";
				my $ret = system($cmd);
				
				unlink("$query_file.tmp", "$query_file.dbrenast.tmp"); # awful names

				if ($ret) { 
					die "Error, cmd $cmd died with ret $ret";
				}
				
			}  ## End of RENAST
			
		#	my $best_ref_file = "tmp.$$.bestref";
		#	open (my $ofh, ">$best_ref_file") or die  $!;
	#		print $ofh $DB_seqs{$best_hit};
		#	close $ofh;

			## Run WigeoN
			$cmd = "$FindBin::Bin/run_WigeoN.pl --query_NAST $query_file ";
			my $ret = system($cmd);
			if ($ret) {
				die "Error, cmd $cmd died with ret $ret";
			}
			
		};
		if ($@) {
			print STDERR "$acc failed:   $@\n\n";
			die;
		}
		
		unlink($query_file, $db_file);

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

	open (my $fh, ">tmp.$$.q") or die $!;
	print $fh ">$acc\n$seq\n";
	close $fh;
	
	my $cmd = "megablast -d $db -i ./tmp.$$.q -e 1e-10 -m 8 -v $num_blast_hits -b $num_blast_hits 2>/dev/null";
		
	my @results = `$cmd`;

	unlink("tmp.$$.q");
	
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

