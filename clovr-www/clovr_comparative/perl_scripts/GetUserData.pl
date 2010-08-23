#!/usr/bin/perl
use warnings;
use strict;
use Storable;

my $topDir = "export";

my $command = "perl UserDataAnnotationInfoGetter.pl $topDir";

(system($command) == 0) ? print "Success:\n" : die "Error in executing command, $command, $?\n";
exit(0);

