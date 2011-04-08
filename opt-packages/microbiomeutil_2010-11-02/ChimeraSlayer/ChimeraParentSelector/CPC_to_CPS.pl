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
#    --CPC_output       tab-delimited parsed output from running ChimeraPhyloChecker
#
#    --query_NAST      multi-fasta file containing query sequences in alignment format
#
#    --db_NAST        db in NAST format
#  
#  ChimeraParentSelector parameters:
#
#   -M match score        (default: +5)
#   -N mismatch penalty   (default: -4)
#   -R min divR           (default: 1.007)  [minimum (query,chimera) / (query,parent) alignment identity ratio]
#   --minQueryCoverage   (default: 90)
#   --maxTraverse        (default: 12)
#
#
#########################################################################################

_EOUSAGE_
	
	;

## Resources:

## option processing
my ($queryNast, $dbNast);
my $prog = "chimeraParentSelector.pl";
my $CPC_output;


&GetOptions ("query_NAST=s" => \$queryNast,
			 "db_NAST=s" => \$dbNast,
			 "CPC_output=s" => \$CPC_output,
	);


unless ($queryNast && $dbNast && $CPC_output) { die $usage; }


main: {
	
	open (my $fh, "$CPC_output") or die "Error, cannot open file $CPC_output";
	while (<$fh>) {
		unless (/^ChimeraSlayer\t/) { next; }
		print;
		
		chomp;
		my @x = split (/\t/);
		my $query_acc = $x[1];
		my @others = ($x[2], $x[3]);
		if ($x[10] eq "YES") {
			my $query_fasta = &cdbyank($query_acc, $queryNast);
			
			my $query_file = "tmp.$$.query";
			open (my $fh, ">$query_file") or die "Error, cannot write to $query_file ";
			print $fh $query_fasta;
			close $fh;
			
			
			my $db_file = "tmp.$$.db";
			open ($fh, ">$db_file") or die "Error, cannot write to $db_file";
			foreach my $hit_acc (@others) {
				my $nast = &cdbyank($hit_acc, $dbNast);
				print $fh $nast;
			}
			close $fh;
			
			eval {
				## run bellerophon
				my $cmd = "$FindBin::Bin/$prog --query_NAST $query_file --db_NAST $db_file --printAlignments ";
				print "\n$cmd\n";
				my $ret = system $cmd;
				if ($ret) {
					die "Error, cmd: $cmd died with ret ($ret)";
				}
			};
			if ($@) {
				print STDERR "$query_acc failed:   $@\n\n";
				die;
			}
			print "//\n"; # spacer.
			
			unlink($query_file, $db_file);
			
			
		}
	}
	
	
	exit(0);
}

