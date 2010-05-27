#!/usr/bin/env perl

use strict;
use warnings;

use Fasta_reader;
use Getopt::Long qw(:config no_ignore_case bundling);

use ColorGradient;

my $refSeqTaxonomy;
my $KmerSize;
my $QueryDB;
my $HTML_OUTPUT_FLAG = 0;

my $MIN_PERCENT_UNIQUE_KMERS = 10;
my $byGenus = 0;


my $usage = <<_EOUSAGE_;

#####################################################################
#
# --query_FASTA     query fasta file
# --db_FASTA        reference db in fasta format (and has taxonomy in the header)
# -K                Kmer size
# 
# Optional:
# --min_percent_unique_kmers    default: 10   (so 10% of unique kmers must correspond to a single taxa to be considered for chiemra)
# --byGenus        default is by Species
# --html 
# --exec_dir       cd to exec_dir before running
#
#####################################################################

_EOUSAGE_

	;

my $help_flag;
my $exec_dir;

&GetOptions ( 'h' => \$help_flag,
			  'query_FASTA=s' => \$QueryDB,
			  'db_FASTA=s' => \$refSeqTaxonomy,
			  'K=s' => \$KmerSize,
			  'min_percent_unique_kmers=i' => \$MIN_PERCENT_UNIQUE_KMERS,
			  'HTML_OUTPUT_FLAG' => \$HTML_OUTPUT_FLAG,
			  'byGenus' => \$byGenus,
			  'html' => \$HTML_OUTPUT_FLAG,
			  'exec_dir=s' => \$exec_dir,
	);

if ($help_flag) {
	die $usage;
}

unless ($QueryDB && $refSeqTaxonomy && $KmerSize) {
	die $usage;
}


my $TAXON_COORD_JOIN_DIST = $KmerSize;

if ($exec_dir) {
	chdir $exec_dir or die "Error, cannot cd to $exec_dir";
}


main: {
	
	
	print STDERR "-parsing sequences and taxonomies\n";
	my %taxonomy_to_sequences = &parse_seqs_n_taxonomy($refSeqTaxonomy);
	
	my %Kmers_to_taxons;
	print STDERR "-indexing Kmers unique to Taxa\n";
	&index_unique_kmers(\%Kmers_to_taxons, \%taxonomy_to_sequences, $KmerSize);
	
	
	print STDERR "-assigning unique Kmers to taxonomies\n";
	&assign_taxonomies_to_Kmers(\%Kmers_to_taxons, \%taxonomy_to_sequences, $KmerSize);
	
	
	&summarize_results($KmerSize, \%Kmers_to_taxons);
		

	&find_chimeras(\%Kmers_to_taxons, $QueryDB, $KmerSize, \%taxonomy_to_sequences);
	

	exit(0);
}


####
sub index_unique_kmers {
	my ($Kmers_to_taxon_counts_href, $taxonomy_to_sequences_href, $KmerSize) = @_;
	

	my $count = 0;
	
	foreach my $taxon (keys %$taxonomy_to_sequences_href) {
		
		my $sequence = $taxonomy_to_sequences_href->{$taxon};
		
		$count++;
		
		print STDERR "\r  ($count) indexing $taxon   ";
		
		&index_Kmer_counts($Kmers_to_taxon_counts_href, $sequence, $KmerSize);
		
	}
	
	## weed out the repetitive Kmers
	foreach my $kmer (keys %$Kmers_to_taxon_counts_href) {
		if ($Kmers_to_taxon_counts_href->{$kmer} > 1) {
			delete $Kmers_to_taxon_counts_href->{$kmer};
		}
	}
	
	return;
	
}


####
sub index_Kmer_counts {
	my ($Kmers_index_href, $sequence, $KmerSize) = @_;

	my %index = &get_Kmers($sequence, $KmerSize);
	
	foreach my $kmer (keys %index) {
		$Kmers_index_href->{$kmer}++;
	}
	
	return;
}
	   
####
sub assign_taxonomies_to_Kmers {
	my ($Kmers_to_taxons_href, $taxonomy_to_sequences_href, $KmerSize) = @_;
	
	my $count = 0;
	
	my %taxon_to_unique_kmers;
	
	foreach my $taxonomy (keys %$taxonomy_to_sequences_href) {
		
		$count++;
		
		print STDERR "\r ($count) assigning $taxonomy     ";
		
		my $sequence = $taxonomy_to_sequences_href->{$taxonomy};
		
		my %Kmers = &get_Kmers($sequence, $KmerSize);

		my $found_unique_Kmer = 0;
		
		foreach my $kmer (keys %Kmers) {
			if (my $val = $Kmers_to_taxons_href->{$kmer}) {
				if ($val != 1) {
					die "Error, got value and it's not 1";
				}
				
				$Kmers_to_taxons_href->{$kmer} = $taxonomy;
				$found_unique_Kmer = 1;
				
				push (@{$taxon_to_unique_kmers{$taxonomy}}, $kmer);
			}
		}
		unless ($found_unique_Kmer) {
			print "!! Warning: No unique ${KmerSize}-Kmer for $taxonomy\n";
		}
	}
	
	## report the unique kmer counts per taxon
	foreach my $taxon (sort keys %taxon_to_unique_kmers) {
		my $num_kmers = scalar(@{$taxon_to_unique_kmers{$taxon}});
		print STDERR "$num_kmers\t$taxon\n";
	}
	

	return;
}


####
sub get_Kmers {
	my ($sequence, $KmerSize) = @_;
	
	my %index;

	my @chars = split (//, lc $sequence);
	
	for (my $i = 0; $i < $#chars - $KmerSize + 1; $i++) {
		my $kmer = join("", @chars[$i..$i+$KmerSize-1]);
		
		if ($kmer =~ /[^gatc]/) { next; } ## only gatc chars
		
		$index{$kmer} = $i+1; # store sequence-based coordinate for unique Kmer
	}
	
	return(%index);
}


####
sub summarize_results {
	my ($KmerSize, $Kmers_to_taxons_href) = @_;

	my %taxons;
	foreach my $taxon (values %$Kmers_to_taxons_href) {
		$taxons{$taxon}++;
	}

	my $num_taxons = scalar(keys %taxons);
	my $num_kmers = scalar(keys %$Kmers_to_taxons_href);

	print "#K:\t$KmerSize\tKmers:\t$num_kmers\ttaxons:\t$num_taxons\n";
	print STDERR "\n\n#K:\t$KmerSize\tKmers:\t$num_kmers\ttaxons:\t$num_taxons\n";
	
	print STDERR join("\n\t", keys %taxons) . "\n";

	return;
}



####
sub parse_seqs_n_taxonomy {
	my ($refSeqTaxonomy) = @_;
	
	my $fasta_reader = new Fasta_reader($refSeqTaxonomy);
	
	my %taxonomy_to_sequences;

	my $count = 0;
	while (my $seq_obj = $fasta_reader->next()) {
		
		$count++;
		my $acc = $seq_obj->get_accession();
		print STDERR "\r   ($count)  parsing $acc   ";

		my $header = $seq_obj->get_header();
		my @x = split (/\t/, $header);
		
		my $taxonomy = pop @x;
		
		@x = split (/\s+/, $header);
		my ($genus, $species) = ($x[1], $x[2]);
		
		unless ($byGenus) {
			$taxonomy .= "; $genus $species";
		}
		
		my $sequence = lc $seq_obj->get_sequence();
		
		if (exists $taxonomy_to_sequences{$taxonomy}) {
			$taxonomy_to_sequences{$taxonomy} .= "n" . $sequence;
		}
		else {
			$taxonomy_to_sequences{$taxonomy} = $sequence;
		}

		
	}


	return(%taxonomy_to_sequences);
	
	
}

####
sub find_chimeras {
	my ($Kmers_to_taxons_href, $QueryDB, $KmerSize, $taxonomy_to_sequences_href) = @_;
	

	my %taxonomy_to_colors;
	if ($HTML_OUTPUT_FLAG) {
		my @taxons = keys %$taxonomy_to_sequences_href;
		my $num_taxons = scalar(@taxons);
		my @colors = &ColorGradient::convert_RGB_hex(&ColorGradient::get_RGB_gradient($num_taxons));
		while (@taxons) {
			my $taxon = shift @taxons;
			my $color = shift @colors;
			$taxonomy_to_colors{$taxon} = $color;
		}
	}

	my $fasta_reader = new Fasta_reader($QueryDB);
	
	while (my $seq_obj = $fasta_reader->next()) {
		
		my $acc = $seq_obj->get_accession();
		
		my $sequence = lc $seq_obj->get_sequence();
		$sequence =~ s/[\.\-]//g; # remove gaps if in alignment format.


		my %kmers = &get_Kmers($sequence, $KmerSize);
		
		my %taxons;

		my %taxon_to_coordinates;

		foreach my $kmer (keys %kmers) {
			
			if (my $taxon = $Kmers_to_taxons_href->{$kmer}) {
				$taxons{$taxon}++;
				
				my $coord = $kmers{$kmer};
				push (@{$taxon_to_coordinates{$taxon}}, $coord);
				
			}
		}
		
		my $taxon_string = "";

		
		my $IS_CHIMERA;
		
		my $htmlseq = $sequence;
		my @htmlchars = split(//, $htmlseq);
		
		if (%taxons) {
			my @t = reverse sort {$taxons{$a}<=>$taxons{$b}} keys %taxons;
			
			my $sum_uniq = &sum(values %taxons);

			my $count_taxon_above_cutoff = 0;
			
			foreach my $taxon (@t) {
				my $num = $taxons{$taxon};
				my $percent = sprintf("%.2f", $num/$sum_uniq*100);
				
				unless ($percent >= $MIN_PERCENT_UNIQUE_KMERS) { next; }
				
				if ($taxon_string) {
					$taxon_string .= "\t";
				}
				
				my @coord_ranges = &define_coord_ranges($taxon, \%taxon_to_coordinates);
				my $coord_string = "";
				foreach my $coordset (@coord_ranges) {
					if ($coord_string) {
						$coord_string .= ",";
					}
					$coord_string .= join("-", @$coordset);
					
					if ($HTML_OUTPUT_FLAG) {
						
						my $color = $taxonomy_to_colors{$taxon} or die "Error, no color for taxon: $taxon";
						for (my $i = $coordset->[0]; $i <= $coordset->[1]; $i++) {
							$htmlchars[$i] = "<font color=\'$color\'>$htmlchars[$i]</font>" unless ($htmlchars[$i] =~ /font/);
						}
					}
				}
				
				$taxon_string .= "$taxon $percent $coord_string";
				
				$count_taxon_above_cutoff++;
				if ($count_taxon_above_cutoff > 1) {
					$IS_CHIMERA = 1;
				}
				
			}
		}
		
		
		if ($HTML_OUTPUT_FLAG) {
			print "<p>\n";
		}
		if ($IS_CHIMERA) {
			print "$acc\tChimera\t$taxon_string\n";
		}
		elsif ($taxon_string) {
			print "$acc\tSingle\t$taxon_string\n";
		}
		else {
			print "$acc\tUnknown\n";
		}
		
		if ($HTML_OUTPUT_FLAG) {
			print "<p>";
			for (my $i = 0; $i <= $#htmlchars; $i++) {
				print $htmlchars[$i];
				if ($i % 60 == 0) {
					print "\n";
				}
			}
			
		}
	}
		
	return;
}


####
sub sum {
	my @vals = @_;

	my $sum = 0;

	foreach my $val (@vals) {
		$sum += $val;
	}

	return($sum);
}

####
sub define_coord_ranges {
	my ($taxon, $taxon_to_coords_href) = @_;

	my @coords = sort {$a<=>$b} @{$taxon_to_coords_href->{$taxon}};
	
	my $coord = shift @coords;
	
	my @ranges = ( [$coord, $coord+$KmerSize-1] );
	
	while (@coords) {
		
		$coord = shift @coords;
		my $orig_coord = $coord;
		$coord = $coord + $KmerSize -1; # coord is the start of the Kmer match. Want the far-right of it.
		my $prev_rend = $ranges[$#ranges]->[1];
		
		if ($coord - $prev_rend <= $TAXON_COORD_JOIN_DIST) {
			# update existing range coordinates
			$ranges[$#ranges]->[1] = $coord;
		}
		else {
			# create new range
			push (@ranges, [$orig_coord, $coord]);
		}
	}
	
	return(@ranges);
}
