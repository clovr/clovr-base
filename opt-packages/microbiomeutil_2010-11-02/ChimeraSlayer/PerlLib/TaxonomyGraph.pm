#!/usr/bin/env perl

use strict;
use warnings;
use Carp;

#### STATIC methods
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
	
	## set root node
	my $node = TaxonNode->new("__ROOT__");
	$self->{nodes}->{"__ROOT__"} = $node;
	

	return($self);
}


sub get_root_node {
	my $self = shift;
	return($self->get_node_by_name("__ROOT__"));
}


sub build_taxonomy_graph_from_taxonomy_list {
	my $self = shift;
	
	my (@taxonomies) = @_;
	
	## should be list of lines where each line contains the format:
	#  DOMAIN; PHYLUM; CLASS; ORDER; FAMILY; GENUS; SPECIES
	
	my %species_counter;
	
	foreach my $taxonomy (@taxonomies) {
		
		
		my @x = split(/;\s+/, $taxonomy);
		
		unless (scalar @x == 7) { confess "Error, taxonomy is incomplete: $taxonomy, should have 7 entries"; }
		

		my $leaf_node = $self->get_or_create_graph_node_by_taxonomy($taxonomy);
		
		$leaf_node->add_attribute(
			{ 
				taxonomy => $taxonomy,
			}
			);
	}
	
	return $self;
}





####
sub get_or_create_graph_node_by_taxonomy {
	my $self = shift;
	my ($taxonomy) = @_;

	$taxonomy =~ s/\s+$//;

	if (my $node = $self->get_node_by_name($taxonomy)) {
		return($node);
	}

	else {
		## find closest ancestral node that exists:
		
		my @taxons = split (/;\s+/, $taxonomy);
		
		for (my $i = $#taxons; $i >= 0; $i--) {
			my $taxon_string = join("; ", @taxons[0..$i]);
			if ( (my $node = $self->get_node_by_name($taxon_string)) || $i == 0) {
				
				if ($i == 0 && ! ref $node) {
					## must instantiate the very first node:
					$node = $self->create_node($taxons[0]);
					$node->set_parent_node( $self->get_node_by_name("__ROOT__") );
				}
				
				my $parent_node = $node;
				for (my $j = $i + 1; $j <= $#taxons; $j++) {
					# instantiate new nodes:
					my $next_taxon_string = join("; ", @taxons[0..$j]);
					my $node = $self->create_node($next_taxon_string);
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
use Carp;
use List::Util qw (min max);

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
sub get_depth {
	my $self = shift;
	
	my $height = 1;
	my $node = $self->{parent_node};
	while ($node) {
		$height++;
		$node = $node->{parent_node};
	}
	
	return($height);
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
	my @children = sort {$a->get_node_name() cmp $b->get_node_name()} @{$self->{children_nodes}};
	return(@children);
	
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



####
sub get_all_leaf_nodes {
	my $self = shift;
	
	my $max_depth = shift; # leave as undef for all leaf nodes

	#print "Getting leaf attributes for $self->{node_name}\n";
	

	if ($self->{attributes} || ($max_depth && $self->get_depth() >= $max_depth)) {
		#print "Got Leaf node.\n";
		
		return($self);
	}
	else {
		my @leaves;
		foreach my $child ($self->get_children()) {
			my @leaf_nodes = $child->get_all_leaf_nodes($max_depth);
			#print "Leaves found for $self->{node_name}: @leaf_atts\n";
			push (@leaves, @leaf_nodes);
		}
		return(@leaves);
	}
	
	die "Error, should never get here";
}

####
sub get_height {
	my $self = shift;
	
	if ($self->{attributes}) {
		# got leaf node
		return(1);
	}
	else {
		my @heights;
		foreach my $child ($self->get_children()) {
			my $child_height = 1 + $child->get_height();
			push (@heights, $child_height);
		}
		return(max(@heights));
	}
}


1; #EOM
