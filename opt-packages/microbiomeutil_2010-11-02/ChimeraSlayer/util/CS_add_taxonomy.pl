#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../PerlLib");

use Fasta_reader;



my %acc_to_taxonomy;

{
	my $fasta_reader = new Fasta_reader("$FindBin::Bin/../../RESOURCES/rRNA16S.gold.fasta");
	while (my $seq_obj = $fasta_reader->next()) {
		my $acc = $seq_obj->get_accession;
		
		my $header = $seq_obj->get_header();
		
		my @header_comp = split(/\t/, $header);                                                                                                                       
		
		my $taxonomy = pop @header_comp;                                                                                                                              
		$header =~ /^\S+\s+([^\t]+)/;                                                                                                                                
		my $species = $1 or die "Error, cannot parse species from header: $header ";                                                                                  
		
		my @taxons = split (/;\s+/, $taxonomy);           
		
		push (@taxons, $species);
		
		$acc_to_taxonomy{$acc} = \@taxons;
	}
}



while (<STDIN>) {
	
	unless (/^ChimeraSlayer/) { 
		print;
		next; 
	}
	chomp;
	my $line = $_;
	my @x = split(/\t/);
	
	my $accA = $x[2];
	my $accB = $x[3];
	
	unless ($x[10] eq 'YES') { next; } # not a chimera, not interested.
	
	if ($accA =~ /\|(\w+)/) {
		$accA = $1;
	}

	if ($accB =~ /\|(\w+)/) {
		$accB = $1;
	}
	

	eval {

		my @taxonsA = &get_taxonomy($accA);
		my @taxonsB = &get_taxonomy($accB);
		
		my ($domainA, $phylumA, $classA, $orderA, $familyA, $genusA, $speciesA) = @taxonsA;
		my ($domainB, $phylumB, $classB, $orderB, $familyB, $genusB, $speciesB)  = @taxonsB;
		
		
		my $level_same = "";
		
		if ($speciesA eq $speciesB) {
			$level_same = "SPECIES";
		}
		elsif ($genusA eq $genusB) {
			$level_same = "GENUS";
		}
		elsif ($familyA eq $familyB) {
			$level_same = "FAMILY";
		}
		elsif ($orderA eq $orderB) {
			$level_same = "ORDER";
		}
		elsif ($classA eq $classB) {
			$level_same = "CLASS";
		}
		elsif ($phylumA eq $phylumB) {
			$level_same = "PHYLUM";
		}
		elsif ($domainA eq $domainB) {
			$level_same = "DOMAIN";
		}
		else {
			$level_same = "UNKNOWN";
		}
		
		print "$line\t$genusA\t$speciesA\t$genusB\t$speciesB\tINTRA-$level_same\n";
	};

	if ($@) {
		print STDERR "Error, cannot find taxonomy info for $accA or $accB\n";
	}


}

exit(0);

####
sub get_taxonomy {
	my $acc = shift;
		
	my @taxons = @{$acc_to_taxonomy{$acc}} or die "Error, no taxonomy for $acc";
	
	return(@taxons);
	
}



