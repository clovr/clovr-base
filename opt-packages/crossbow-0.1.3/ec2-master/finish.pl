#!/usr/bin/perl -w

##
# finish.pl
#
#  Authors: Ben Langmead & Michael C. Schatz
#     Date: October 20, 2009
#
# Put a proper chromosome name back onto all Crossbow records.
#

use strict;
use warnings;
use Getopt::Long;

my %cmap = ();
sub loadCmap($) {
	my $f = shift;
	if($f ne "" && -e $f) {
		open CMAP, "$f";
		while(<CMAP>) {
			chomp;
			my @s = split;
			next if $s[0] eq "" || $#s < 1;
			$cmap{$s[1]} = $s[0];
		}
		close(CMAP);
	}
}

my $cmapstr = "";
GetOptions ("cmap=s" => \$cmapstr) || die "Bad options";

loadCmap($cmapstr);
while(<STDIN>) {
	next unless $_ ne "";
	my $off = index($_, "\t");
	next unless $off > 0;
	my $chr = substr($_, 0, $off);
	if(defined($cmap{$chr})) {
		# Correct the chromosome name
		$chr = $cmap{$chr};
		print "chr$chr\t".substr($_, $off + 1);
	} else {
		# Don't know how to correct it, so leave it
		print "$_";
	}
}
