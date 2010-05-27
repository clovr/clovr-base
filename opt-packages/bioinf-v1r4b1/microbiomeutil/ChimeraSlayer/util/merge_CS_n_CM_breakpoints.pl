#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 CSlayer.output  CMaligner.output\n\n";

my $CS_file = $ARGV[0] or die $usage;
my $CM_file = $ARGV[1] or die $usage;


main: {
	
	my %CS_acc_pairs_to_brk = &parse_CS_breaks($CS_file);
	
	my %CM_acc_pairs_to_brk = &parse_CM_breaks($CM_file);

	# header
	print "#query\tparentA\tparentB\tCS\tCM\n";
	
	# data pts.
	foreach my $acc (keys %CS_acc_pairs_to_brk) {
		
		my ($query_acc, $accA, $accB) = split(/$;/, $acc);
		
		my $CS_brk = $CS_acc_pairs_to_brk{$acc};

		my $CM_brk = $CM_acc_pairs_to_brk{$acc};

		if (defined $CS_brk && defined $CM_brk) {
			print join("\t", $query_acc, $accA, $accB, $CS_brk, $CM_brk) . "\n";
		}
	}
	
	exit(0);
}


####
sub parse_CS_breaks {
	my ($CS_file) = @_;

	my %CS_brks;
	
	open (my $fh, $CS_file) or die "Error, cannot open file $CS_file";
	while (<$fh>) {
		my @x = split(/\t/);
		
		my $acc = $x[1];
		my $accA = $x[2];
		my $accB = $x[3];
		
		my $chimeraFlag = $x[10];
		unless ($chimeraFlag eq 'YES') { next; }

		my $break_txt = $x[12];
		$break_txt =~ s/ECO://;

		my ($lend, $rend) = split(/-/, $break_txt);
		
		my $breakpt = int( ($lend+$rend)/2 + 0.5);
		
		my $acc_token = join("$;", $acc, sort($accA,$accB));

		$CS_brks{$acc_token} = $breakpt;
	}
	
	return(%CS_brks);
}
	
####
sub parse_CM_breaks {
	my ($CM_file) = @_;

	my %CM_brks;

	open (my $fh, $CM_file) or die "Error, cannot open $CM_file";
	while (<$fh>) {
		chomp;
		my ($chimMalign, $acc, $chimeraFlag, $segments) = split(/\t/);
		
		unless ($chimeraFlag eq 'YES') { next; }
		
		my @coordPairs;
		while ($segments =~ /\((\S+),[^\)]+ECO:(\d+)-(\d+)/g) {
			my ($seg_acc, $coordA, $coordB) = ($1, $2, $3);
			push (@coordPairs, [$seg_acc, $coordA, $coordB]);
		}

		## find breakpoints
		my @breakpoints;
		my $coordpair = shift @coordPairs;
		while (@coordPairs) {
			
			my $prev_acc = $coordpair->[0];
			my $prev_rend = $coordpair->[2];
			
			my $next_coordpair = shift @coordPairs;
			my $next_acc = $next_coordpair->[0];
			my $next_lend = $next_coordpair->[1];

			my $breakpoint = int( ($prev_rend+$next_lend)/2 + 0.5);
			push (@breakpoints, [$prev_acc, $next_acc, $breakpoint]);

			$coordpair = $next_coordpair;
		}

		if (scalar (@breakpoints) > 1) { next; } # ignoring multiple CM breaks

		# store breakpoints
		my $breakpoint = shift @breakpoints;
		
		my ($accA, $accB, $pt) = @$breakpoint;
			
		my $token = join("$;", $acc, sort($accA, $accB));
		
		$CM_brks{$token} = $pt;
	}

	close $fh;

	return(%CM_brks);
}


