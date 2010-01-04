#!/usr/bin/perl

##
# bowtie_wrap.pl
#
#  Authors: Ben Langmead & Michael C. Schatz
#     Date: July 2009
#

# First arg = path to bowtie binary
my $bowtie = shift(@ARGV);
chmod 0777, $bowtie;
# Rest of args = args to bowtie
my $args = join(" ", @ARGV);
open OUT, ">.tmp.$$" || die "Could not open .tmp.$$ for writing";
my $records = 0;
# Shunt all of the input to a file
while(<STDIN>) { print OUT $_; $records++; }
close(OUT);
print STDERR "$records reads downloaded\n";
if($records > 0) {
	print STDERR "reporter:counter:Bowtie,Reads downloaded,$records\n";
	# Print a bit of the reads file, for sanity-checking purposes
	print STDERR "head -4 .tmp.$$:\n";
	print STDERR `head -4 .tmp.$$`;
	print STDERR "tail -4 .tmp.$$:\n";
	print STDERR `tail -4 .tmp.$$`;
	# Main bowtie invocation
	my $cmd = "$bowtie $args .tmp.$$";
	print STDERR "Running: $cmd\n";
	print STDERR "reporter:counter:Bowtie,Reads given to Bowtie,$records\n";
	my $ret = system ($cmd);
	$ret == 0 || die "$bowtie exited with non-zero exitlevel $ret";
	system("rm -f .tmp.$$");
	print STDERR "$records reads aligned\n";
} else {
	# Sometimes we'll get a spurious 0-sized input file named '/' or ''
	# or somesuch; if we don't print anything, Hadoop's GzipCodec bails
	# with an NPE and the whole thing fails.  This sidesteps that.
	print "# placeholder for 0-record mapper\n";
	print STDERR "Printed placeholder\n";
}
