=head1 NAME

group_blast_hits.pl - group btab BLAST hits by query and/or subject ids

=head1 SYNOPSIS

usage:	group_blast_hits.pl [--input|-i <blast_btab>]
	[--output_dir|-d <output_directory>]
	[--group_by_query|-q] [--group_by_subject|-s]
	[--num_files_per_dir|-n <number_of_files_per_directory>]
	[--help|-h]

=head1 OPTIONS

B<--group_by_query, -q>
	group hits by query id

B<--group_by_subject, -s>
	group hits by subject id

B<--num_files_per_dir, -n>
	number of files per directory [default = 500]

B<--help, h>
	This help screen

=head1 DESCRIPTION

This script will group btab BLAST hits by query and/or subject, creating a
separate file for each group.  Once num_files_per_dir has been reached, it
will create a new directory and continue writing to this new directory.

=head1 CONTACT

Ed lee (elee@tigr.org)

=cut

use strict;
use warnings;

use IO::File;
use Getopt::Long qw(:config no_ignore_case bundling);
use File::Basename;
use POSIX;
use Pod::Usage;

use Blast::BlastHitDataType;

my $in_name		= "/dev/stdin";
my $in			= undef;
my $out_dir		= ".";
my $group_by_query	= 0;
my $group_by_subject	= 0;
my $num_files_per_dir	= 500;

&parse_options;
&group_blast_hits;

sub print_usage
{
	pod2usage( {-exitval => 1, -verbose => 2, -output => \*STDOUT} );
}

sub parse_options
{
	my %opts = ();
	GetOptions(\%opts, "input|i=s", "output_dir|d=s",
		   "group_by_query|q", "group_by_subject|s",
		   "num_files_per_dir|n=i", "help|h");
	&print_usage if $opts{help};
	$group_by_query = 1 if $opts{group_by_query};
	$group_by_subject = 1 if $opts{group_by_subject};
	$in_name = $opts{input} if $opts{input};
	$out_dir = $opts{output_dir} if $opts{output_dir};
	$in = new IO::File($in_name) or
		die "Error reading input hits $in_name: $!";
	$num_files_per_dir = $opts{num_files_per_dir} if
		$opts{num_files_per_dir};
}

sub group_blast_hits
{
	my @hits = ();
	process_hits(\@hits);
	@hits = sort hits_comparator @hits;
	output_hits(\@hits);
}

sub hits_comparator
{
	if ($group_by_query && $group_by_subject) {
		if ($a->GetQueryName eq $b->GetQueryName) {
			return $a->GetSubjectName cmp $b->GetSubjectName;
		}
		return $a->GetQueryName cmp $b->GetQueryName;
	}
	elsif ($group_by_query) {
		return $a->GetQueryName cmp $b->GetQueryName;
	}
	elsif ($group_by_subject) {
		return $a->GetSubjectName cmp $b->GetSubjectName;
	}
}

sub process_hits
{
	my $hits = shift;
	while (my $line = <$in>) {
		chomp $line;
		push @$hits, new Blast::BlastHitDataType($line);
	}
}

sub output_hits
{
	my $hits = shift;
	my $out = undef;
	my $chunk = 0;
	my $dir_chunk = 0;
	my $num_written = POSIX::INT_MAX;
	my $prev_query_id = "";
	my $prev_subject_id = "";
	foreach my $hit (@$hits) {

		if (($group_by_query &&
		     $prev_query_id ne $hit->GetQueryName) ||
		    ($group_by_subject &&
		     $prev_subject_id ne $hit->GetSubjectName)) {
			if (++$num_written >= $num_files_per_dir) {
				$num_written = 0;
				++$dir_chunk;
				mkdir("$out_dir/$dir_chunk");
			}
			my $out_name = "$out_dir/$dir_chunk/" .
				basename($in_name) .
				"." . ++$chunk;
			$out = new IO::File($out_name, "w")
				or die "Error writing output chunk " .
					"$out_name: $!";
			$prev_query_id = $hit->GetQueryName;
			$prev_subject_id = $hit->GetSubjectName;
		}
		print $out $hit->ToString, "\n";
	}
}
