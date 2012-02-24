#!/usr/bin/perl
use strict;
use warnings;
# format_qiime_reps_for_uchime.pl
# takes an OTU file from Qiime and a set
# of representatives, then outputs a fasta file with the 
# representatives and the abundance information for uchime.
use Getopt::Std;

use vars qw/$opt_i $opt_r $opt_o $opt_l/;
getopts("i:r:o:l:");

my $otufile  = $opt_i;
my $repfile  = $opt_r;
my $outfile  = $opt_o;
my $listfile = $opt_l;

my %counts = ();
my $sum = 0;

open IN, "$otufile" or die "Cannot open $otufile!!\n";
while(<IN>){
  chomp($_);
  my @A = split "\t", $_;
  my $otunum = $A[0];
  my $totalcount = $#A;
  $sum += $totalcount;
  $counts{$otunum} = $totalcount;
}
close IN;

foreach my $o (keys %counts){
  $counts{$o} = 100*$counts{$o}/$sum;
}

my $cseq  = "";
my $cname = "";
open OUT, ">$outfile" or die;
`echo $outfile > $listfile`;
open IN, "$repfile" or die "Can't open $repfile!\n";
while(<IN>){
  chomp($_);
  if ($_ =~ />/){
    if ($cseq ne ""){
      UserFunction($cseq, $cname);
    }
    my @A = split " ", $_;
    $cname = substr($A[0], 1);
    $cseq  = "";
  }else{
    $cseq .= $_;   
  }
}
close IN;
# last time!
UserFunction($cseq, $cname);

close OUT;

sub UserFunction
{
  my ($seq, $name) = @_;
  my $ab = $counts{$name};
  print OUT ">$name/ab=$ab/\n";
  print OUT "$seq\n";
}

