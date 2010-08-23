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
#use Data::Dumper;

###################             CONSTATNS               #################

my $ROOT = '/';
my $NODE = 'node';
my $ID	= 'id';
my $CHILDREN = 'children';
my $TEXT = 'text';
my $LEAF = 'leaf';
my $LEAF_COUNT = 'leaf_count';
my $TRUE = 1;
my $FALSE = 0;
my $CHECKED = 'checked';
my $MSG = 'IDs';
my $SEQ_FETCHED = 'seq_fetched';
my $MAP_FETCHED = 'map_fetched';
my $ANNOT = 'ANNOTATION_INFO';
my $MAP = 'MAP_INFO';
my $EXPANDED = 'expanded';
my $REF_SEQ_FILE = "/mnt/scratch/clovr_comparative/RefSeqList.txt";
my $MAP_FILE = "/mnt/scratch/clovr_comparative/MapOrgList.txt";

###################             GLOBAL VARIABLES        #################

my $q = new CGI;
my $binaryFile = '../binary_files/NcbiTreeWidgetDataStructure';
my ($root) = retrieve($binaryFile) or die "Error in retrieving $binaryFile\n";

###################            SUBS DECLARATION         #################

sub getAllChildNodes ($);
sub getRefSeqs ($);
sub getMapNames ($);
sub helperFetchMapNames ($);
sub writeToFile ($$$);
sub appendToFile ($$);

###################            MAIN PROGRAM             #################

#sends jason
my $params = $q->Vars;
print "Content-type: text/html\n\n";
if($$params{$MSG}) {
	my $refSeqs = [];
	my $refMaps = getMapNames($$params{$MSG});
	foreach(split(', ',$$params{$MSG})) {
		push @$refSeqs, @{getRefSeqs($_)};
	}
	my $ref_seq_info = join(" ", @$refSeqs);
	my $map_info = join("\n", @$refMaps);
	appendToFile($REF_SEQ_FILE, $ref_seq_info);
	appendToFile($MAP_FILE, $map_info);
	my $run_pipeline = "perl InvokePipeline.cgi '$REF_SEQ_FILE' '$MAP_FILE' '$$params{'pipeline'}' '$$params{'genbank_file'}' '$$params{'map_file'}' '$$params{'pipeline_name'}'" ;
	system($run_pipeline) == 0 or die "system $run_pipeline failed, $?, \n";
} 
else {
	my $arrayRef = getAllChildNodes($$params{$NODE});
	if($$params{$NODE} eq $ROOT) {
		$arrayRef = addUserDataNode($arrayRef);
	}
	print encode_json($arrayRef);
}
exit(0);

##################             END OF MAIN               #################


sub getAllChildNodes ($) {
	my ($id) = @_;
	my $refArray = [];
	while(my ($key,$value) = each %{$root->{$id}->{$CHILDREN}}) {
		my $refHash = {};
		$$refHash{$ID} = $key;
		$$refHash{$TEXT} = $$root{$key}{$TEXT}." (".$$root{$key}{$LEAF_COUNT}.")";
		$$refHash{$CHECKED}  = $$params{$CHECKED} eq 'true' ? JSON::PP::true : JSON::PP::false;
		if($$root{$key}{$LEAF}) {
			$$refHash{$LEAF} = JSON::PP::true;
		}
		elsif($$root{$id}{$LEAF_COUNT} && $$root{$id}{$LEAF_COUNT} == $$root{$key}{$LEAF_COUNT}) {
			$$refHash{$EXPANDED} = JSON::PP::true;
			push @{$$refHash{$CHILDREN}}, @{getAllChildNodes($key)};
		}
		push @$refArray, $refHash;
	}
	return $refArray;
}

sub getRefSeqs ($) {
	my ($id) = @_;
	my $refSeqs = [];
	unless($$root{$id}{$SEQ_FETCHED}) {
		if($$root{$id}{$LEAF}) {
			$$root{$id}{$SEQ_FETCHED} = $TRUE;
			foreach(@{$$root{$id}{$ANNOT}}) {
				push @$refSeqs, $$_[0];
			}
		}
		elsif(defined @{$$root{$id}{$ANNOT}}) {
			$$root{$id}{$SEQ_FETCHED} = $TRUE;
			foreach(@{$$root{$id}{$ANNOT}}) {
				push @$refSeqs, $$_[0];
			}
		}
	}
	while(my ($key,$value) = each %{$$root{$id}{$CHILDREN}}) {
		push @$refSeqs, @{getRefSeqs($key)};
	}
	return $refSeqs;
}

sub getMapNames ($) {
	my ($info) = @_;
	my $array = [];
	foreach(split(', ', $info)) {
		push @$array, @{helperFetchMapNames($_)};	
	}
	return $array;
}

sub helperFetchMapNames ($) {
	my ($id) = @_;
	my $info = [];
	if($$root{$id}{$MAP} && !$$root{$id}{$MAP_FETCHED}) {
		$$root{$id}{$MAP_FETCHED} = $TRUE;
		push @$info, @{$$root{$id}{$MAP}};
	}
	foreach(keys %{$$root{$id}{$CHILDREN}}) {
		push @$info, @{helperFetchMapNames($_)};
	}
	return $info;
}

sub appendToFile ($$) {
	my ($file, $info) = @_;
	open(OFH, ">>$file") or die "Error in appending to the file, $file, $!\n";
	print OFH $info;
	close OFH;
}

sub writeToFile ($$$) {
	my ($file, $info, $separator) = @_;
	open(OFH, ">$file") or die "Error in writing to the file, $file, $!\n";
	print OFH $info.$separator;
	close OFH;
}
sub addUserDataNode {
	my ($ref) = @_;
	my $userSelInfo;
	my $userData = retrieve('../binary_files/NcbiUserDataStructure') or die "Error retrieving the user data structure $!\n";
	my $refHash;
	$$refHash{$ID} = 'userData_userData';
	$$refHash{$EXPANDED} = JSON::PP::true;
	$$refHash{$CHILDREN} = [];
	my $counter = 0;
	while(my ($key,$value) = each %$userData) {
		my $tempHash = {};
		$$tempHash{$ID} = 'userData_'.$key,
		my $thisKeyRefseqCount = scalar@{$$userData{$key}{$ANNOT}};
		$counter += $thisKeyRefseqCount;
		$$tempHash{$TEXT} = $key.' ('.$thisKeyRefseqCount.')';
		$$tempHash{$LEAF} = JSON::PP::true;
		push @{$$refHash{$CHILDREN}}, $tempHash;
		push @{$$userSelInfo{'refSeqInfo'}}, getUserDataRefSeqList($userData, $key);
		push @{$$userSelInfo{'mapInfo'}}, @{$$userData{$key}{$MAP}};
		
	}
	my $uniq = {};
	foreach(@{$$userSelInfo{'mapInfo'}}) {
		$$uniq{$_}++;
	}
	my @uniqMapNames = keys%$uniq;
	writeToFile($REF_SEQ_FILE, join(" ", @{$$userSelInfo{'refSeqInfo'}}), " ");
	writeToFile($MAP_FILE, join("\n", @uniqMapNames), "\n");
	$$refHash{$TEXT} = 'User Data ('.$counter.')';
	push @$ref, $refHash;
	return $ref;
}

sub getUserDataRefSeqList {
	my ($data, $key) = @_;
	my @refSeqList = ();
	foreach(@{$$data{$key}{$ANNOT}}) {
		push @refSeqList, $$_[0];
	}
	return @refSeqList;
}


