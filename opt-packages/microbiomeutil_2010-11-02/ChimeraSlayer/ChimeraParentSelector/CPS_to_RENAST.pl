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
$0
##########################################################################################
#
#  Required:
#
#    --query_NAST      multi-fasta file containing query sequences in alignment format
#
#    --db_NAST        db in NAST format
#
#    --CPS_output      ChimeraParentSelector output (file.CPS)
#
#########################################################################################


_EOUSAGE_
	
	;


## required options
my ($query_NAST, $db_NAST, $CPS_file);


&GetOptions (
	
	"query_NAST=s" => \$query_NAST,
	"db_NAST=s" => \$db_NAST,
	"CPS_output=s" => \$CPS_file,
	);

unless ($query_NAST && $db_NAST && $CPS_file) { die $usage; }

my $TMP = $ENV{TMPDIR} || "/tmp";

main: {
	
	open (my $fh, $CPS_file) or die "Error, cannot open file $CPS_file";
	while (<$fh>) {
		print STDERR "processing: $_";
		chomp;
		my @toks = split(/\t/);
		
		my $query_acc = $toks[1];
		
		if ($toks[2] ne 'YES') {
			## use original sequence alignment
			my $query_nast = &cdbyank($query_acc, $query_NAST);
			print $query_nast;
			next;
		}
		
		## RENAST using CM-chosen alignments:
		
		my $query_seq = &cdbyank_linear($query_acc, $query_NAST);
		$query_seq =~ s/[\.\-]//g; # remove any gap characters.
		
		my $query_file = "$TMP/tmp.$$.query";
		my $db_file = "$TMP/tmp.$$.db";
		open (my $ofh, ">$query_file") or die "Error, cannot write to $query_file ";
		print $ofh ">$query_acc\n$query_seq\n";
		close $ofh;
		
		my @accs_for_renast;
		
		while ($toks[3] =~ /\((\S+), NAST:(\d+)-(\d+), ECO:\d+-\d+, RawLen:(\d+), G:([\d\.]+), L:([\d\.]+), ([\d
\.]+)\)/g) {
			
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
				
		open ($ofh, ">$query_file.dbrenast.tmp") or die $!;
		foreach my $acc (@accs_for_renast) {
			my $fasta_seq = &cdbyank($acc, $db_NAST);
			print $ofh $fasta_seq . "\n";
		}
		close $ofh;

		## RENAST it
		my $cmd = "$FindBin::Bin/../../NAST-iEr/NAST-iEr $query_file.dbrenast.tmp $query_file";
		my $renast = `$cmd`;
		my $ret = $?;
		print $renast;
		
		if ($ret) { 
			die "Error, cmd $cmd died with ret $ret";
		}

		unlink("$query_file", "$query_file.dbrenast.tmp"); # awful names
		
	}

	
	exit(0);
}

