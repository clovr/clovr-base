#!/usr/bin/env perl

use strict;
use warnings;

use CdbTools;
use Data::Dumper;

use lib ("/seq/microbiome/Tool-Dev/microbiomeutil/CMCS/PerlLib/");
use AlignCompare;

use List::Util qw (shuffle);

my $usage = "usage: $0 TaxonomyFile Alignments.NAST\n\n";

my $taxonomy_file = $ARGV[0] or die $usage;
my $NAST_file = $ARGV[1] or die $usage;

my %MAX_COMPARES_PER_LEVEL = (PHYLUM => 500,
							  CLASS => 50,
							  ORDER => 50,
							  FAMILY => 50,
							  GENUS => 50,
							  SPECIES => 50,
	);

my $taxonomy_graph = TaxonomyGraph->new();

my %taxonomy_vals;

main: {

	&build_taxonomy_graph($taxonomy_file);
	

	my @accessions = keys %taxonomy_vals;

	for (my $i = 0; $i <$#accessions; $i++) {
		
		for (my $j = $i + 1; $j <= $#accessions; $j++) {

			eval {
				my $accA = $accessions[$i];
				my $accB = $accessions[$j];
				
				my $sequenceA = &cdbyank_linear($accA, $NAST_file);
				my $sequenceB = &cdbyank_linear($accB, $NAST_file);
				
				my $per_ID = sprintf("%.2f", &compute_per_ID($sequenceA, $sequenceB));
				
				my $taxon_compare_level = &get_common_taxon_level($taxonomy_vals{$accA}, $taxonomy_vals{$accB});
				
				
				print "$taxon_compare_level\t$accA\t" . $taxonomy_vals{$accA} . "\t$accB\t" . $taxonomy_vals{$accB} . "\t$per_ID\n";
			};
			
			print "\n"; # add spacer.
		}
	}
	
	exit(0);
}

####
sub retrieve_taxon_nodes {
	my ($taxon, $nodes_aref) = @_;

	my @taxon_nodes;
	
	foreach my $node (@$nodes_aref) {
		if ($node->{taxon} eq $taxon) {
			push (@taxon_nodes, $node);
		}
	}

	return(@taxon_nodes);
}




####
sub build_taxonomy_graph {
	my ($taxonomy_file) = @_;

	my %species_counter;

	open (my $fh, $taxonomy_file) or die "Error, cannot open $taxonomy_file";
	while (<$fh>) {
		chomp;
		my ($acc, $species_name, $taxonomy) = split (/\t/);
		
		my ($genus, $species, @rest) = split (/\s+/, $species_name);
		
		$taxonomy .= "; $genus $species";
		
		$taxonomy .= "; " . "${species_name} " . ++$species_counter{$taxonomy};
		
		my $leaf_node = &get_graph_node($taxonomy);
		
		$taxonomy_vals{$acc} = $taxonomy;
		
		$leaf_node->add_attribute(
			{ 
				acc => $acc, 
				species_name => $species_name,
				taxonomy => $taxonomy,
				
			}
			);
	}
	close $fh;
	
	return;
}

####
sub get_graph_node {
	my ($taxonomy) = @_;

	$taxonomy =~ s/\s+$//;

	if (my $node = $taxonomy_graph->get_node_by_name($taxonomy)) {
		return($node);
	}

	else {
		## find closest ancestral node that exists:
		
		my @taxons = split (/;\s+/, $taxonomy);
		
		for (my $i = $#taxons; $i >= 0; $i--) {
			my $taxon_string = join("; ", @taxons[0..$i]);
			if ( (my $node = $taxonomy_graph->get_node_by_name($taxon_string)) || $i == 0) {
				
				if ($i == 0 && ! ref $node) {
					## must instantiate the very first node:
					$node = $taxonomy_graph->create_node($taxons[0]);
					
				}
				
				my $parent_node = $node;
				for (my $j = $i + 1; $j <= $#taxons; $j++) {
					# instantiate new nodes:
					my $next_taxon_string = join("; ", @taxons[0..$j]);
					my $node = $taxonomy_graph->create_node($next_taxon_string);
					$node->set_parent_node($parent_node);
					
					$parent_node = $node;
				}
				return($parent_node);
			}
		}
		
		die "Error!! shouldn't get here";
	}
	
}



####
sub compute_per_ID {
	my ($seqA, $seqB) = @_;

		
	my @charsA = split(//, uc $seqA);
	my @charsB = split(//, uc $seqB);
	
	my $aligned_chars = 0;
	my $same_chars = 0;

	my $lend_bound = &AlignCompare::find_lend_match(\@charsA, \@charsB);
	my $rend_bound = &AlignCompare::find_rend_match(\@charsA, \@charsB);

	
	my $subseqA = join("", @charsA[$lend_bound..$rend_bound]);
	my $subseqB = join("", @charsB[$lend_bound..$rend_bound]);

	my $per_id = &AlignCompare::compute_per_ID($subseqA, $subseqB);
	
	return($per_id);

}



####
sub get_common_taxon_level {
	my ($taxonomyA, $taxonomyB) = @_;

	my @TAXON_LEVELS = qw (DOMAIN PHYLUM CLASS ORDER FAMILY GENUS SPECIES);

	my @taxonsA = split(/;\s+/, $taxonomyA);
	my @taxonsB = split(/;\s+/, $taxonomyB);
	
	for (my $i = $#taxonsA; $i >= 0; $i--) {
		
		if ($taxonsA[$i] eq $taxonsB[$i]) {
			return($TAXON_LEVELS[$i]);
		}
	}

	die "Error, taxonomies have nothing in common: $taxonomyA\t$taxonomyB ";
}






#######################################
package TaxonomyGraph;

use strict;
use warnings;
use Carp;

sub new {
	my ($packagename) = shift;
	
	my $self = { 
		nodes => {}, 
		
	};
	
	bless ($self, $packagename);
	

	return($self);
}

####
sub create_node {
	my $self = shift;
	my ($node_name) = @_;

	if (exists($self->{nodes}->{$node_name})) {
		confess "Error, node already exists: $node_name ";
	}

	my $node = TaxonNode->new($node_name);

	$self->{nodes}->{$node_name} = $node;
	
	return ($node);
}


####
sub get_node_by_name {
	my $self = shift;
	my ($node_name) = @_;

	if (my $node = $self->{nodes}->{$node_name}) {
		return($node);
	}
	else {
		return(undef);
	}
}


####
sub get_all_nodes {
	my $self = shift;

	return(values %{$self->{nodes}});
}


#####################################
package TaxonNode;

use strict;
use warnings;

sub new {
	my ($packagename) = shift;
	my ($node_name) = @_;
	
	my $self = { node_name => $node_name,
				 parent_node => undef,
				 children_nodes => [],
				 attributes => undef,  # becomes an aref on add_attibutes()
	};
	
	bless($self, $packagename);

	$self->{depth} = $self->get_node_depth();
	$self->{taxon} = $self->get_taxonomy_depth();
	
	
	return($self);
}

####
sub get_node_name {
	my $self = shift;
	
	return($self->{node_name});
}


####
sub set_parent_node {
	my $self = shift;
	my ($parent_node) = @_;

	$self->{parent_node} = $parent_node;
	
	$parent_node->add_child($self);
	
	
	return;
}

####
sub add_child {
	my $self = shift;
	my $child_to_add = shift;
	foreach my $child (@{$self->{children_nodes}}) {
		if ($child eq $child_to_add) {
			return;
		}
	}
	
	## hasn't been added yet:
	push (@{$self->{children_nodes}}, $child_to_add);
}


####
sub add_attribute {
	my $self = shift;

	my (@attributes) = @_;

	unless (ref $self->{attributes}) {
		$self->{attributes} = [];
	}
	
	push (@{$self->{attributes}}, @attributes);
	
	return;
}


####
sub get_node_depth {
	my $self = shift;
	
	my @taxons = split (/;\s+/, $self->get_node_name());
	
	return($#taxons);
}


####
sub get_children {
	my $self = shift;
	return(@{$self->{children_nodes}});
}


####
sub get_taxonomy_depth {
	my $self = shift;
	my $node_name = $self->get_node_name();
	
	my @taxon_levels = qw (DOMAIN PHYLUM CLASS ORDER FAMILY GENUS SPECIES INSTANCE);
	
	
	my $depth = $self->get_node_depth();
	
	return($taxon_levels[$depth]);
}

####
sub get_all_leaf_attributes {
	my $self = shift;
	
	#print "Getting leaf attributes for $self->{node_name}\n";
	

	if ($self->{attributes}) {
		#print "Got Leaf node.\n";
		
		return(@{$self->{attributes}});
	}
	else {
		my @leaf_attributes;
		foreach my $child ($self->get_children()) {
			my @leaf_atts = $child->get_all_leaf_attributes();
			#print "Leaves found for $self->{node_name}: @leaf_atts\n";
			push (@leaf_attributes, @leaf_atts);
		}
		return(@leaf_attributes);
	}
	
	die "Error, should never get here";
}


