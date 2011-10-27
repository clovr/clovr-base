#!/usr/bin/perl
use strict;
my @f=split(/,/, $ARGV[0]);
foreach my $i (@f) {
    print `vp-transfer-dataset --tag-name $i --dst-cluster $ARGV[1] --block --expand 2>&1`;
}
