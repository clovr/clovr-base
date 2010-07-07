#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

#*********************************************************************
#  CreateRDP_Table.pl*
#  * This program takes a RDP bayesian classifier output file, a groups
#  file created by mothur, and a metadata file and creates a set of 
#  ordered matrices that may be looked over by the user. 

# The output is *.<taxon level>.csv, multiple levels will be produced. 

#  Author: james robert white, whitej@umd.edu  
#  Last modified: June 28, 2010 
#*********************************************************************
use Getopt::Std;
use warnings;

use vars qw/$opt_r $opt_g $opt_m $opt_p/;

getopts("r:g:m:p:");

my $usage = "Usage:  $0 \
                -r RDP Bayesian classifier output file\
                -g groups file generated by mothur_trim_seqs\
                -m metadata file describing associations between samples\
                -p output prefix [<prefix>.<taxon level>.csv]
                \n";

die $usage unless defined $opt_m
              and defined $opt_g
              and defined $opt_p
              and defined $opt_r;

my $prefix = $opt_p;

#*********************************************************************
# GLOBALS
#*********************************************************************
my %samples        = ();
my %activesamples  = ();
my @orderedsamples = ();
my %groups         = ();
my %seqmap         = ();
my %data           = ();
my @levels         = qw/phylum class order family genus/;
my %activefeatures = ();
my %groupnames = ();
#*********************************************************************

#*********************************************************************
# Begin parsing files
#*********************************************************************
open IN, "$opt_g" or die "Can't open Mothur groups file for reading!!\n";
while(<IN>){
  chomp($_);
  my @A = split "\t", $_;
  $A[0] =~s/^\s+|\s+$//g;
  $A[1] =~s/^\s+|\s+$//g;
  $activesamples{$A[1]} = 1; 
  $seqmap{$A[0]} = $A[1];
}
close IN;

open IN, "$opt_m" or die "Can't open Meta file for reading!!\n";
while(<IN>){
  chomp($_);
  my @A = split /\,/, $_;
  $A[2] =~s/^\s+|\s+$//g;
  if (!defined($A[3])){ # then there are no classes for the samples
    push @{$groups{"NoClassDef"}}, $A[2];    
  }else{
    $A[3] =~s/^\s+|\s+$//g;
    $samples{$A[2]} = $A[3];
    push @{$groups{$A[3]}}, $A[2];  
    $groupnames{$A[3]} = 1;
  }
}
close IN;



my $current_seq = "";
open IN, "$opt_r" or die "Can't open RDP output file for reading!!\n";
while(<IN>){
  chomp($_);
  if ($_ =~ /^>/){
    my @A = split " ", $_;
    $current_seq = substr($A[0],1); 
  }else{
    # Root; 1.0; Bacteria; 0.99; Proteobacteria; 0.71; Betaproteobacteria; 0.19; Procabacteriales; 0.16; Procabacteriaceae; 0.16; Procabacter; 0.16; 
    my @A = split "; ", $_;
    for my $i (0 .. $#A){
      $A[$i] =~ s/^\s+|\s+$//g;
      $A[$i]  =~ s/^\"+|\"+$//g;
    }
    # phylum assignment
    if (!defined($data{$seqmap{$current_seq}}{"phylum"}{$A[4]})){
      $data{$seqmap{$current_seq}}{"phylum"}{$A[4]} = 1;
      $activefeatures{"phylum"}{$A[4]} = 1; 
    }else{
      $data{$seqmap{$current_seq}}{"phylum"}{$A[4]}++;
    } 
    
    # class assignment
    if (!defined($data{$seqmap{$current_seq}}{"class"}{$A[6]})){
      $data{$seqmap{$current_seq}}{"class"}{$A[6]} = 1;
      $activefeatures{"class"}{$A[6]} = 1;
    }else{
      $data{$seqmap{$current_seq}}{"class"}{$A[6]}++;
    }
    
    #genus assignment
    if (!defined($data{$seqmap{$current_seq}}{"genus"}{$A[$#A-1]})){
      $data{$seqmap{$current_seq}}{"genus"}{$A[$#A-1]} = 1;
      $activefeatures{"genus"}{$A[$#A-1]} = 1;
    }else{
      $data{$seqmap{$current_seq}}{"genus"}{$A[$#A-1]}++;
    }
 
    #family assignment
    if (!defined($data{$seqmap{$current_seq}}{"family"}{$A[$#A-3]})){
      $data{$seqmap{$current_seq}}{"family"}{$A[$#A-3]} = 1;
      $activefeatures{"family"}{$A[$#A-3]} = 1;
    }else{
      $data{$seqmap{$current_seq}}{"family"}{$A[$#A-3]}++;
    }
  
    # order assignment
    my $odex = 8;
    if (!defined($A[$odex])){
      $odex = $#A;
    }

    if ($A[$odex] =~ /subclass/){
      $odex+=2;
    }    

    if (!defined($data{$seqmap{$current_seq}}{"order"}{$A[$odex]})){
      $data{$seqmap{$current_seq}}{"order"}{$A[$odex]} = 1;
      $activefeatures{"order"}{$A[$odex]} = 1;
    }else{
      $data{$seqmap{$current_seq}}{"order"}{$A[$odex]}++;
    }
  }
}
close IN;

foreach my $type (%groups){
  foreach my $s (@{$groups{$type}}){
    if (defined($activesamples{$s})){
      push @orderedsamples, $s;
    }
  }
}


foreach my $l (@levels){
  zeroOut($l);
  printCounts($l);
}

my @gs = sort keys %groupnames;
foreach my $l (@levels){
  for my $i (0 .. $#gs){
  for my $j (0 .. $#gs){
    next if ($j >= $i);
    printPairedGroups($l, $gs[$i], $gs[$j]);
  }
  }
}
  

#*********************************************************************
# Subroutines
#*********************************************************************
sub zeroOut
{
  my ($taxstr) = @_;
  foreach my $f (sort keys %{$activefeatures{$taxstr}}){
    foreach my $s (sort keys %activesamples){
      $data{$s}{$taxstr}{$f} = 0 if !defined($data{$s}{$taxstr}{$f});
    }
  }
  return;
}


sub printCounts
{
  my ($level) = @_;
  open OUT, ">$prefix.$level.tsv" or die "Can't open $prefix.$level.tsv for writing!\n"; 
  
  for my $s (@orderedsamples){
    print OUT "\t$s";
  } 
   print OUT "\n";

  foreach my $f (sort keys %{$activefeatures{$level}}){
    print OUT "$f";
    for my $s (@orderedsamples){
      print OUT "\t$data{$s}{$level}{$f}";
    } 
    print OUT "\n";
  } 
  close OUT;
}


sub printPairedGroups
{
  my ($level, $g1, $g2) = @_;

  my @pairedorderedsamples = ();
  my $g1count = 0;
  foreach my $s (@{$groups{$g1}}){
     if (defined($activesamples{$s})){
       push @pairedorderedsamples, $s;
       $g1count++; 
     }
  }
  my $g2count = 0;
  foreach my $s (@{$groups{$g2}}){
     if (defined($activesamples{$s})){
     push @pairedorderedsamples, $s;
     $g2count++;
    }
  }
   
  return if ($g1 <= 0 or $g2 <=0);
  return if (($g1 == 1 and $g2 != 1) or ($g1 != 1 and $g2 == 1));  
 
  open OUT, ">$prefix.$level.$g1\_vs_$g2.$g1count-$g2count.2tsv" or die "Can't open $prefix.$level.$g1\_vs_$g2.$g1count--$g2count.2tsv for writing!\n";
  for my $s (0 .. $#pairedorderedsamples){
    print OUT "\t$pairedorderedsamples[$s]";
  }
  print OUT "\n";

  foreach my $f (sort keys %{$activefeatures{$level}}){
    print OUT "$f";
    for my $s (0 .. $#pairedorderedsamples){
      print OUT "\t$data{$pairedorderedsamples[$s]}{$level}{$f}";
    }
    print OUT "\n";
  }
  close OUT;
}
