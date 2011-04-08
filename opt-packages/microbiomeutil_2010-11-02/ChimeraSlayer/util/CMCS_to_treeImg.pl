#!/usr/bin/env perl

use strict;
use warnings;
use List::Util qw (min max);

use GD;

use FindBin;
use lib ("$FindBin::Bin/PerlLib");

use TaxonomyGraph;

use Getopt::Long qw(:config no_ignore_case bundling);


my $usage = <<_EOUSAGE_;

################################################################
#
# Required:
#
#  --CMCS_parsed    the CMCS .parsed file
#
#  --db_FASTA       the reference 16S fasta file (taxonomy included in the headers)
#
# Optional:
#
#  --image_height    default: 800
#  --image_width     default: 700
#  --ratio_tree_width   default: 0.6
#  --max_depth          
#
###################################################################

_EOUSAGE_

	;



my $cmcs_parsed;
my $ref16Sfile;
my $IMAGE_HEIGHT = 800;
my $IMAGE_WIDTH = 700;
my $RATIO_TREE_WIDTH = 0.6;
my $MAX_DEPTH;

my $help_flag;

&GetOptions( 'h' => \$help_flag,
			 'CMCS_parsed=s' => \$cmcs_parsed,
			 'db_FASTA=s' => \$ref16Sfile,
			 'image_height=i' => \$IMAGE_HEIGHT,
			 'image_width=i' => \$IMAGE_WIDTH,
			 'ratio_tree_width=f' => \$RATIO_TREE_WIDTH,
			 'max_depth=i' => \$MAX_DEPTH,
	);


if ($help_flag || (! ($cmcs_parsed && $ref16Sfile) ) ) {
	die $usage;
}

# globals
my $MAX_LINE_THICKNESS = 5;
my $DEBUG = 0;

main: {
	
	my %chimera_counts;
	my %chimera_parents;
	
	## parse the chimeras
	{
		open (my $fh, $cmcs_parsed) or die "Error, cannot open file $cmcs_parsed";
		while (<$fh>) {
			chomp;
			my @x = split(/\t/);
			if ($x[9] eq "YES") {
				## got chimera
				my @chimera_pairs = sort ($x[1], $x[2]);
				foreach my $chimera_parent (@chimera_pairs) {
					$chimera_parents{$chimera_parent} = 1;
				}
				my $chimera_token = join(";", @chimera_pairs);

				# count chimeras according to parents
				$chimera_counts{$chimera_token}++; 
			}
		}
		close $fh;
	}

	## get the taxonomies for the parents:
	my %acc_to_taxonomy = &parse_parent_taxonomies($ref16Sfile, \%chimera_parents);
	
	my $taxonomyGraph = new TaxonomyGraph();
	$taxonomyGraph->build_taxonomy_graph_from_taxonomy_list(values %acc_to_taxonomy);
	
	&build_taxon_tree_image($taxonomyGraph, \%acc_to_taxonomy, \%chimera_counts);
	
	exit(0);
}

####
sub parse_parent_taxonomies {
	my ($ref16Sfile, $chimera_parents_href) = @_;
	
	my %acc_to_taxonomy;

	open (my $fh, $ref16Sfile) or die "Error, cannot open file $ref16Sfile";
	while (<$fh>) {
		chomp;
		my $line = $_;
		if (/^>(\S+)/) {
			my $acc = $1;
			if ($chimera_parents_href->{$acc}) {
				# get taxonomy
				my @x = split(/\t/, $line);
				my $taxonomy = pop @x;
				$taxonomy =~ s/\s+$//;
				
				$taxonomy .= "; $acc";
				
				$acc_to_taxonomy{$acc}= $taxonomy;
			}
		}
	}
	close $fh;

	## make sure all parents have a taxonomy assigned
	if (scalar (keys %$chimera_parents_href) != scalar(keys %acc_to_taxonomy)) {
		confess "Error, not all chimera parents have taxonomy found";
	}
	
	return(%acc_to_taxonomy);
}

####
sub build_taxon_tree_image {
	my ($taxonomyGraph, $acc_to_taxonomy_href, $chimera_counts_href) = @_;

	my $image_height = $IMAGE_HEIGHT;
	my $image_width = $IMAGE_WIDTH;
	
	my $tree_width = int($RATIO_TREE_WIDTH * $image_width);
	
	my %pixel_saver;  ## retain coordinates of end of leaf nodes
	
	my $root_node = $taxonomyGraph->get_root_node();
	
	my $depth = $MAX_DEPTH || $root_node->get_height();
	print STDERR "taxonomy depth: $depth\n" if $DEBUG;
	
	# draw root:
	my $pixels_per_level = int($tree_width/$depth);
	
	my $image = new GD::Image($image_width, $image_height);
	my $white = $image->colorAllocate(255,255,255);
	my $black = $image->colorAllocate(0,0,0);
	my $green = $image->colorAllocate(0,255,0);
	
	$image->fill(0,0,$white);

	#$image->rectangle(0,0,$tree_width, $image_height, $black);

	&draw_tree( { image => $image,
				  
				  pixel_saver => \%pixel_saver,
				  
				  colors => { 
					  black => $black, 
					  green => $green,
				  },
				  
				  pixels_per_level => $pixels_per_level,
				  
				  node => $root_node,
				  
				  panel_bottom => $image_height,
				  panel_top => 0,
				  panel_left => 0,
				  panel_right => $tree_width,
				
				}
		);
	
	
	## Draw the chimera Freq Correlator
	my $freq_panel_left = $tree_width;
	my $freq_panel_right = $image_width;
	my $freq_panel_width = $freq_panel_right - $freq_panel_left;
	my $red = $image->colorAllocate(255,0,0);

	#$image->rectangle($freq_panel_left, 0, $freq_panel_right, $image_height, $red);
	
	my $max_chimera = max(values %$chimera_counts_href);

	foreach my $chimera (keys %$chimera_counts_href) {
		my ($accA, $accB) = split(/;/, $chimera);
		
		my $count_chimera = $chimera_counts_href->{$chimera};
		my $ratio_chimeras = $count_chimera / $max_chimera;
		
		my $thickness = int($ratio_chimeras * $MAX_LINE_THICKNESS + 1) || 1;
		$image->setThickness($thickness);

		my $coordset_A = $pixel_saver{$accA} or confess "Error, no coordinates for $accA";
		my $coordset_B = $pixel_saver{$accB} or confess "Error, no coordinates for $accB";
		
		my ($xA, $yA) = @$coordset_A;
		my ($xB, $yB) = @$coordset_B;

		my $diff_Y = abs($yA - $yB);
		my $ratio_diff_Y = $diff_Y / $image_height;
		my $delta_X = int($ratio_diff_Y * $freq_panel_width);
		
		my $pos_X = $delta_X + $freq_panel_left;
		my $mid_Y = int(($yA + $yB)/2);
		
				
		# draw lines
		$image->line($xA, $yA, $pos_X, $mid_Y, $red);
		$image->line($xB, $yB, $pos_X, $mid_Y, $red);
	
		print STDERR "$image->line($xA, $yA, $pos_X, $mid_Y, $red);\n" if $DEBUG;
		print STDERR "$image->line($xB, $yB, $pos_X, $mid_Y, $red);\n" if $DEBUG;
		
	}
	
	$image->setThickness(1); # restore default

	print $image->png();

	exit(0);
}

####
sub draw_tree {
	my ($params_href) = @_;
	
	## unwrap params
	my $image = $params_href->{image};
	my $pixel_saver_href = $params_href->{pixel_saver};
	my $colors = $params_href->{colors};
	my $pixels_per_level = $params_href->{pixels_per_level};
	my $node = $params_href->{node};
	my $panel_bottom = $params_href->{panel_bottom};
	my $panel_top = $params_href->{panel_top};
	my $panel_left = $params_href->{panel_left};
	my $panel_right = $params_href->{panel_right};
	

	#$image->rectangle($panel_left, $panel_top, $panel_right, $panel_bottom, $colors->{green});
	
	
	my $midpt = int( ($panel_top + $panel_bottom) / 2);
	print STDERR "$image->line($panel_left, $midpt, $panel_left + $pixels_per_level, $colors->{black});\n" if $DEBUG;
	$image->line($panel_left, $midpt, $panel_left + $pixels_per_level, $midpt, $colors->{black});
	$image->arc($panel_left, $midpt, 5, 5, 0, 360, $colors->{black});
	$image->fill($panel_left, $midpt, $colors->{black});
	
	my $panel_height = $panel_bottom - $panel_top;

	my $node_name = $node->get_node_name();

	my $depth = $node->get_depth();

	print STDERR "Node: $node_name (depth: $depth)\n";

	my @taxons = split(/;\s+/, $node_name);
	my $taxon = pop @taxons;
	
	## section children
	my @children = $node->get_children();

	
    if (@children) {
		# internal node
		# draw name above line
		
		$image->string(gdSmallFont, $panel_left, $midpt, $taxon, $colors->{black});
		
	
	}
    
	my $stop_draw_flag = 0;
	
	if ( ($MAX_DEPTH && $depth >= $MAX_DEPTH) || ! @children) {
		
		$stop_draw_flag = 1;
		
		# leaf node
		## store info in pixel saver
		print STDERR "\tLEAF: $node_name (depth: $depth)\n";
		foreach my $leaf_node ($node->get_all_leaf_nodes()) {
			my $leaf_node_name = $leaf_node->get_node_name();
			my @x = split(/;\s+/, $leaf_node_name);
			my $acc = pop @x;
			
			$pixel_saver_href->{$acc} = [$panel_left + $pixels_per_level, $midpt]; # rightmost point
		}
	}
	

	unless ($stop_draw_flag) {
		my @all_leaves = $node->get_all_leaf_nodes($MAX_DEPTH);
		my $num_leaves = scalar(@all_leaves);
		
		if ($DEBUG) {
			foreach my $leaf (@all_leaves) {
				print STDERR "\t\tleaf: " . $leaf->get_node_name() . " " . "depth: " . $leaf->get_depth() . "\n";
			}
		}

		
		my $prev_top = $panel_top;
		
		my @midpts;
				
		foreach my $child (@children) {
			my @child_leaves = $child->get_all_leaf_nodes($MAX_DEPTH);
			my $num_children = scalar(@child_leaves);
						
			my $ratio_height = $num_children / $num_leaves;
			print STDERR "$ratio_height = $num_children / $num_leaves \n" if $DEBUG;
			
			my $child_panel_height = int($ratio_height * $panel_height);
			
			my $mid = &draw_tree( { image => $image,
									pixel_saver => $pixel_saver_href,
									colors => $colors,
									pixels_per_level => $pixels_per_level,
									node => $child,
									panel_bottom => $prev_top + $child_panel_height,
									panel_top => $prev_top,
									panel_left => $panel_left + $pixels_per_level,
									panel_right => $panel_right,
								  } );
			
			$prev_top += $child_panel_height;
			
			push (@midpts, $mid);
		}
		
		## draw line from top to bottom mids at panel_left
		if (scalar @midpts > 1) {
			@midpts = sort {$a<=>$b} @midpts; # probably unnecessary
			print STDERR "MIDS: @midpts\n" if $DEBUG;
			my $top_pt = shift @midpts;
			my $bottom_pt = pop @midpts;
			my $join_line_x = $panel_left + $pixels_per_level;
			
			$image->line($join_line_x, $top_pt, $join_line_x, $bottom_pt, $colors->{black});
		}
	}
	
	
	return ($midpt);
	
	
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
