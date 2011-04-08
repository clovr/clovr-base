#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 CM.output\n\n";

my $CM_file = $ARGV[0] or die $usage;

open (my $fh, $CM_file) or die "Error, cannot open $CM_file";

while (<$fh>) {
	chomp;
	
	unless (/^ChimeraMaligner/) { next; }
	
	my @x = split(/\t/);
	
	unless ($x[2] eq "YES") { next; }

	my $acc = $x[1];

	my @match_files;

	my @y_coords;
	
	for (my $i = 3; $i <= $#x; $i++) {
		
		my $match_line = $x[$i];
		
		my $match_file = "$$.matches.$i.dat";
		push (@match_files, $match_file);
		open (my $ofh, ">$match_file") or die "Error, cannot write file $match_file";
		
		my @matches = split(/;/, $match_line);
		
		
		
		foreach my $match (@matches) {
			
			$match =~ /\((\d+)-(\d+),\s+\S+,\s+G:\S+,\s+L:(\d+)/ or die "Error, no regex match for $match";
			my $lend = $1;
			my $rend = $2;
			my $per_ID = $3;

			print $ofh "$lend\t$per_ID\n$rend\t$per_ID\n\n";
		
			push (@y_coords, $per_ID);
		}
		close $ofh;
	}

	# write gnuplot script
	open (my $gscript_ofh, ">gnuscript.$$.txt") or die "Error, cannot write gnuplot script";
	
	print $gscript_ofh "set term png color\n";
	my $ofile = $acc;
	$ofile =~ s/\W/_/g;
	print $gscript_ofh "set output \'CM.$ofile.png\'\n";
	
	use List::Util qw (min max);
	my $min_y = min(@y_coords);
	my $max_y = max(@y_coords);

	$min_y-=2;
	$max_y+=2;
	
	print $gscript_ofh "set yrange[$min_y:$max_y]\n";

	foreach my $match_file (@match_files) {
		$match_file = "\'$match_file\' w lp";
		#print "MATCH: $match_file\n";
		
	}
	
	my $plot_line = "plot " . join(",", @match_files) . "\n";
	
	print $gscript_ofh $plot_line . "\n";
	
	close $gscript_ofh;

	system "gnuplot gnuscript.$$.txt";

	#unlink("gnuscript.$$.txt", @match_files);

	print "Wrote image file: CM.$ofile.png\n";

}

		
