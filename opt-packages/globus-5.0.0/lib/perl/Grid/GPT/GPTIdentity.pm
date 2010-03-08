package Grid::GPT::GPTIdentity;

use strict;
use Carp;

require Exporter;
use vars       qw($VERSION @ISA);

# set the version for version checking
$VERSION     = 0.01;

@ISA         = qw(Exporter);

sub gpt_version {
    return "3.2";
}

sub print_gpt_version {
  print "Grid Packaging Tools (GPT) Version ",gpt_version(),"\n";
  exit;
}

1;
__END__
