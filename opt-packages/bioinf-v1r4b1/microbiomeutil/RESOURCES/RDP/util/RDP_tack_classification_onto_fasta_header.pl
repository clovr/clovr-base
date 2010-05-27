#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 RDP_classification_results  FASTA_file\n\n";

my $RDP_results = $ARGV[0] or die $usage;
my $fasta_file = $ARGV[1] or die $usage;


my %acc_to_class;
{
	open (my $fh, $RDP_results) or die $!;
	while (<$fh>) {
		if (/^>(\S+)/) {
			my $acc = $1;
			
			my $class = <$fh>;
			
			chomp $class;
			
			my @x = split (/;\s+/, $class);
			
			my @taxons;
			while (@x) {
				my $taxon = shift @x;
				my $score = shift @x;
				unless ($taxon eq "Root") {
					push (@taxons, $taxon);
				}
			}

			#print "$acc\t" . join(";", @taxons) . "\n";
			$acc_to_class{$acc} = join("; ", @taxons);
			
		}
	}
	close $fh;
}

open (my $fh, $fasta_file) or die $!;
while (<$fh>) {
	my $line = $_;
	
	if (/^>(\S+)/) {
		my $acc = $1;
		chomp $line;
		my $taxonomy = $acc_to_class{$acc};
		
		print "$line\t$taxonomy\n";
	}
	else {
		print;
	}
}


exit(0);


