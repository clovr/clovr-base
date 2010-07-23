#!/usr/bin/perl
# Name: NcbiJsonsender.cgi
# Desc: Gets the Ncbi taxonomy data structure generated by ParseNcbiOboTaxaAndWriteToDiskFile.pl
#		Sends the children of given node back to client
# 		Sends data in the form of JSON
# Dependencies: CGI, JSON::PP, Storable
# @author: Mahesh Vangala
###################         LIBRARIES & PRAGMAS         #################

use strict;
use warnings;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use JSON::PP;
use Storable;

###################             CONSTATNS               #################

use constant node => 'node';
use constant id	=> 'id';
use constant children => 'children';
use constant text => 'text';
use constant leaf => 'leaf';
use constant leaf_count => 'leaf_count';
use constant true => 1;
use constant false => 0;

###################             GLOBAL VARIABLES        #################

my $q = new CGI;
my $binaryFile = 'NcbiOboTaxaDataStructure';
my ($root,$topNodes) = @{retrieve($binaryFile)} or die "Error in retrieving $binaryFile\n";

###################            SUBS DECLARATION         #################

sub getAllRootNodes ();
sub getAllChildNodes ($);

###################            MAIN PROGRAM             #################

#sends jason
my $params = $q->Vars;
print "Content-type: text/html\n\n";
my $json = ($$params{node} eq '/') ? encode_json(getAllRootNodes())
								   : encode_json(getAllChildNodes($$params{node}));
print $json;
exit(0);

##################             END OF MAIN               #################

sub getAllRootNodes () {
	my $refArray = [];
	foreach(@{$topNodes}) {
		my $refHash = {};
		$$refHash{id} = $_;
		if($$root{$_}{leaf}) {
			$$refHash{leaf} = JSON::PP::true;
			$$refHash{text} = $$root{$_}{text};	
		}
		else {
			$$refHash{text} = $$root{$_}{text}." (count:'".$$root{$_}{leaf_count}."')";			
		}
		push @$refArray, $refHash;
	}
	return $refArray;
}

sub getAllChildNodes ($) {
	my ($id) = @_;
	my $refArray = [];
	while(my ($key,$value) = each %{$root->{$id}->{children}}) {
		my $refHash = {};
		$$refHash{id} = $key;		
		if($$root{$key}{leaf}) {
			$$refHash{leaf} = JSON::PP::true;
			$$refHash{text} = $$root{$key}{text};
		}
		else {
			$$refHash{text} = $$root{$key}{text}." (count:'".$$root{$key}{leaf_count}."')";
		}
		push @$refArray, $refHash;
	}
	return $refArray;
}
