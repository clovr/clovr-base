#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");


my $usage = "usage: $0 db.NAST db.FASTA\n\n";

my $db = $ARGV[0] or die $usage;
my $blastable = $ARGV[1] or die $usage;

my $prev = $db;
for my $i (1..25) {
	
	print STDERR "// processing round $i\n";
	
	my $cmd = "$FindBin::Bin/../run_NAST-iEr.pl --query_FASTA $prev --db_NAST $prev --db_FASTA $blastable > $i.NAST 2>/dev/null";

	&process_cmd($cmd);


	$prev = "$i.NAST";
}

exit(0);

####
sub process_cmd {
	my $cmd = shift;

	my $ret = system($cmd);
	if ($ret) {
		die "Error, cmd $cmd died with ret $ret";
	}

	return;
}

