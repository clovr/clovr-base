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
#
#  Required:
#
#    --CPS_output       output from running ChimeraParentSelector
#
#    --query_NAST      multi-fasta file containing query sequences in alignment format
#
#    --db_NAST        db in NAST format
#  
#
#  ## parameters to tune ChimeraPhyloChecker to your liking:
#
#    --windowSize      default 50
#    --windowStep      default 5
#    -R                min divergence ratio for chimera assignment (default 1.007)    
#    -P                     min perID for CM fragment and for parent/fragment identity in CS (default: 90)
#    --num_parents_test     number of top parent candidates to explore with CS (default: 3)
#    -S                percent of SNPs to sample on each side of breakpoint for computing bootstrap support (default: 10)
#    --minBS           min bootstrap support (default: 90)
#    --MAX_CHIMERA_PARENT_PER_ID   default: 100 (turned off)
#    
#    -h     help menu
#    -K     keep tmp files
#
#     --printAlignments
#
#########################################################################################



_EOUSAGE_
	
	;

## Resources:

## option processing
my ($query_NAST, $db_NAST, $CPS_output);

my $minPerID = 90;
my $minBS;
my $minDivR;
my $windowSize;
my $windowStep;

my $percentSNPsSample;
my $num_parents_test = 3;

my $help_flag;
my $KEEP_TMP_FILES;

my $printAlignments;
my $MAX_CHIMERA_PARENT_PER_ID;

&GetOptions ("query_NAST=s" => \$query_NAST,
			 "db_NAST=s" => \$db_NAST,
			 "CPS_output=s" => \$CPS_output,
			 
			 "P=f" => \$minPerID,
			 "R=f" => \$minDivR,
			 "windowSize=i" => \$windowSize,
			 "windowStep=i" => \$windowStep,
			 "minBS=i" => \$minBS,

	 
			 "S=i" => \$percentSNPsSample,
			 "num_parents_test=i" => \$num_parents_test,

			 "printAlignments" => \$printAlignments,
			 "MAX_CHIMERA_PARENT_PER_ID=f" => \$MAX_CHIMERA_PARENT_PER_ID,

			 'h' => \$help_flag,
			 
			 'K' => \$KEEP_TMP_FILES,
	);


if ($help_flag) {
	die $usage;
}


unless ($query_NAST && $db_NAST && $CPS_output) { die $usage; }


main: {
	
	open (my $fh, "$CPS_output") or die "Error, cannot open file $CPS_output";
	while (<$fh>) {
		my $line = $_;
		chomp;
		if (/^ChimeraParentSelector/) {
			my @x = split (/\t/);
			my $query_acc = $x[1];
			
			if ($x[2] eq "NO") {
				#print "# OK\t$query_acc\n";
				print join("\t", "ChimeraSlayer", $query_acc, "NULL", "NULL", 
						   "-1", "-1", "-1", 
						   "-1", "-1", "-1",
						   "NO") . "\n";
				
			} 
			elsif ($x[2] eq "UNKNOWN") {
				#print "# UNKNOWN\t$query_acc\n";
				print join("\t", "ChimeraSlayer", $query_acc, "NULL", "NULL", 
						   "-1", "-1", "-1", 
						   "-1", "-1", "-1",
						   "UNKNOWN") . "\n";
				
			}
			elsif ($x[2] eq "YES") {
				
				# format:  (AY094367|S000395648, NAST:1988-6815, RawLen:1096, G:96.24, L:100.00, 1.039)
				
				my %others;
				while ($line =~ /\((\S+), NAST:(\d+)-(\d+), ECO:\d+-\d+, RawLen:(\d+), G:([\d\.]+), L:([\d\.]+), ([\d\.]+)\)/g) {
					
					my $acc = $1;

					my $range_lend = $2;
					my $range_rend = $3;
					
					my $segmentLength = $4;
					
					my $global_per_id = $5;
					my $local_per_id = $6;
					my $divR = $7;
					
					my $score = $segmentLength * $local_per_id;
					if ($local_per_id >= $minPerID) {
						$others{$acc} += $score;
					}
					
				}
				
				
				my $query_seq = &cdbyank_linear($query_acc, $query_NAST);
								
				my $query_file = "/tmp/tmp.$$.query";
				open (my $fh, ">$query_file") or die "Error, cannot write to $query_file ";
				print $fh ">$query_acc\n$query_seq\n";
				close $fh;
				
				my @others = reverse sort {$others{$a} <=> $others{$b}} keys %others;
				if (scalar (@others) > $num_parents_test) {
					@others = @others[0..$num_parents_test-1];
				}
				
				my $db_file = "/tmp/tmp.$$.db";
				open ($fh, ">$db_file") or die "Error, cannot write to $db_file";
				foreach my $hit_acc (@others) {
					my $nast = &cdbyank($hit_acc, $db_NAST);
					print $fh $nast;
				}
				close $fh;
				
				eval {
									
					## run ChimeraPhyloChecker
					my $cmd = "$FindBin::Bin/ChimeraPhyloChecker.pl --query_NAST $query_file --db_NAST $db_file ";
									
					if (defined $minPerID) {
						$cmd .= " -P $minPerID ";
					}
					if (defined $minDivR) {
						$cmd .= " -R $minDivR ";
					}
					if (defined $minBS) {
						$cmd .= " --minBS $minBS ";
					}
					
					if (defined $windowSize) {
						$cmd .= " --winSize $windowSize ";
					}
					if (defined $windowStep) {
						$cmd .= " --winStep $windowStep ";
					}
					if (defined $percentSNPsSample) {
						$cmd .= " -S $percentSNPsSample ";
					}
					if (defined $MAX_CHIMERA_PARENT_PER_ID) {
						$cmd .= " --MAX_CHIMERA_PARENT_PER_ID ";
					}
					
					if ($printAlignments) {
						$cmd .= " --printAlignments ";
					}
					
					print STDERR "$cmd\n";
					my $ret = system $cmd;
					if ($ret) {
						die "Error, cmd: $cmd died with ret ($ret)";
					}
				};
				if ($@) {
					print STDERR "$query_acc failed:   $@\n\n";
					die;
				}
				
				unlink($query_file, $db_file) unless $KEEP_TMP_FILES;
				
								
			}
		}
	}
	
	exit(0);
}

