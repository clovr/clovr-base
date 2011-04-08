#!/usr/bin/env perl

use strict;
use warnings;

my %genus_counter;

while (<>) {
	if (/^>/) {
		my $line  = $_;
		chomp $line;
		my @x = split(/\t/, $line);
		
		my $taxons = pop @x;
		my @taxa = split(/;\s/, $taxons);
		
		my $genus = pop @taxa;
		my $phylum = $taxa[1];
		
		#print "$phylum\t$genus\n";
		
		$genus_counter{$phylum}->{$genus}++;


	}
}


foreach my $phylum (keys %genus_counter) {

	my $count = 0;
	
	foreach my $genus (keys %{$genus_counter{$phylum}}) {
		if ( (my $count = $genus_counter{$phylum}->{$genus}) > 1) {
			print "$phylum\t$genus\t$count\n";
		}
	}

	#print $phylum . "\t$count\n";
}



exit(0);

