#!/usr/bin/env perl

use strict;
use warnings;



my @progs = qw(blastall megablast formatdb cdbyank cdbfasta);

my $error_flag = 0;

foreach my $prog (@progs) {
	my $path = `which $prog`;
	chomp $path;
	
	unless ($path && -e $path) {
		$error_flag = 1;
		print STDERR "\n\n\nError, cannot find path to $prog\n\n\n";
	}
}


exit($error_flag);

