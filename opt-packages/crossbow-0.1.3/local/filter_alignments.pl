#!/usr/bin/perl -w
use strict;

my $gchr  = shift;
my $gspos = shift;
my $gepos = shift;

die "filter_alignments.pl chromosome start end\n" 
  if (!defined $gchr || !defined $gspos || !defined $gepos);

while (<>)
{
  my @vals = split /\s+/, $_;

  my $chr  = $vals[0];
  my $spos = $vals[2];
  my $seq  = $vals[4];

  my $epos = $spos + length($seq) - 1;

  if (($chr eq $gchr) &&
      ($epos >= ($gspos)) &&
      ($spos <= ($gepos)))
  {
    print;
  }
}
