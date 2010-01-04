#!/usr/bin/perl -w

##
# copy_mapper.pl
#
#  Authors: Michael C. Schatz & Ben Langmead
#     Date: 6/26/2009
#
# Mapper for Crossbow bulk copies of FASTQ reads.
#

use strict;
use warnings;
use Getopt::Long;

my $compress = "gzip";
my $push = "";
my $s3cmd = "s3cmd-0.9.9/s3cmd";
my $hadoop = `find /usr/local | grep 'bin/hadoop\$'`;
chomp($hadoop);

my $helpflag = undef;
my $skipfirst = undef;
my $owner = undef;
my $stopAfter = 0;
my $maxPerFile = 0;

GetOptions(
	"compress=s" => \$compress,
	"push=s" => \$push,
	"s3cmd=s" => \$s3cmd,
	"hadoop=s" => \$hadoop,
	"stop=i" => \$stopAfter,
	"maxperfile=i" => \$maxPerFile,
	"h" => \$helpflag,
	"s" => \$skipfirst,
	"owner=s" => \$owner)
	|| die "GetOptions failed\n";

if ($helpflag)
{
	print "copy_mapper.pl [options] -push <dest>\n";
	print "\n";
	print "  Single End Input Format:  URL MD5\n";
	print "  Paired End Input Format:  URL_1 MD5_1 URL_2 MD5_2\n";
	print "  Set MD5=0 to skip MD5 checks\n";
	print "\n";
	print "Options:\n";
	print "  -push=<dest>   URL to store preprocessed files (hdfs:// or s3://)\n";
	print "  -compress=[gzip|bzip2|none] Compression type for preprocessed files (default: $compress)\n";
	print "  -s3cmd=<path>  Path to s3cmd executable (default: $s3cmd)\n";
	print "  -hadoop=<path> Path to hadoop executable (default: $hadoop)\n";
	print "  -maxperfile=<int> Maximum number of preprocessed reads per output file\n";
	print "  -s Skip the first field, may be necessary for using NLineInputFormat\n";
	exit(0);
}

$push eq "" || -x $hadoop || die "Cannot run hadoop script $hadoop\n";

if ($push =~ /^s3/) {
	-x $s3cmd || die "Pushng to s3, but cannot run s3cmd script $s3cmd\n";
}
elsif ($push =~ /^hdfs/)
{
	-x $hadoop || die "Pushing to hdfs, but cannot run hadoop script $hadoop\n";
}

my $unpaired = 0;
my $paired = 0;

if (defined $owner && $push ne "")
{
	my $cmd = "$hadoop fs -mkdir $push";
	print STDERR "$cmd\n";
	system($cmd);
	$cmd = "$hadoop fs -chown $owner $push";
	print STDERR "$cmd\n";
	system($cmd);
}

sub s3cmdify($) {
	my $path = shift;
	$path =~ s/^s3n:/s3:/;
	$path =~ s/^s3:\/\/[^\/]*\@/s3:\/\//;
	return $path;
}

##
# Calculate the md5 hash of an object in S3 using s3cmd.
#
sub s3md5($) {
	my $path = shift;
	$path = s3cmdify($path);
	my $md5 = `$s3cmd --list-md5 ls $path | awk '{print \$4}'`;
	chomp($md5);
	length($md5) == 32 || die "Bad MD5 obtained from s3: $md5\n";
	return $md5;
}

##
# Push a file from the local filesystem to another filesystem (perhaps
# HDFS, perhaps S3) using hadoop fs -cp.
#
sub pushS3($) {
	my $file = shift;
	-e $file || die "No such file $file";
	$push ne "" || die "pushS3() called but no destination is set";
	print STDERR "reporter:counter:Crossbow Bulk Copy,Read data pushed to S3,".(-s $file)."\n";

	if($compress eq "bzip2") {
		my $cmd = "bzip2 $file";
		print STDERR "$cmd\n";
		system($cmd) == 0 || die "Command $cmd failed";
		$file .= ".bz2";
		-e $file || die "No such file $file after compression";
	} elsif($compress eq "gzip") {
		my $cmd = "gzip $file";
		print STDERR "$cmd\n";
		system($cmd) == 0 || die "Command $cmd failed";
		$file .= ".gz";
		-e $file || die "No such file $file after compression";
	} elsif($compress eq "none") {
		## nothing to do
	} elsif($compress ne "") {
		die "Did not recognize compression type $compress";
	}
	-e $file || die "No such file $file";

	my $md5 = `md5sum $file | cut -d' ' -f 1`;
	chomp($md5);
	length($md5) == 32 || die "Bad MD5 calculated locally: $md5";

	if ($push =~ /^hdfs/)
	{
		my $cmd = "$hadoop fs -put $file $push";
		print STDERR "$cmd\n";
		system($cmd) == 0 || die "Command failed: $cmd";

		if (defined $owner) {
			my $cmd = "$hadoop fs -chown $owner $push/$file";
			print STDERR "$cmd\n";
			system($cmd) == 0 || die "Command failed: $cmd";
		}
	}
	else
	{
		# For s3cmd, change s3n -> s3 and remove login info
		my $s3cmd_push = s3cmdify($push);

		my $cmd = "$s3cmd put $file $s3cmd_push/$file";
		print STDERR "$cmd\n";
		system($cmd) == 0 || die "Command failed: $cmd";

		my $rmd5 = s3md5("$push/$file");
		$md5 eq $rmd5 || die "Local MD5 $md5 does not equal S3 md5 $rmd5 for file $s3cmd_push/$file";
	}

	print STDERR "reporter:counter:Crossbow Bulk Copy,Read data pushed to S3 (compressed),".(-s $file)."\n" if $compress ne "";
}

## Download a file with wget
sub wget($$$) {
	my ($fname, $url, $md5) = @_;
	my $cmd = "wget -O $fname $url";
	print STDERR "$cmd\n";
	my $rc = system ($cmd);
	die "wget failed: $url $rc\n" if $rc;
}

## Download a file with hadoop fs -get
sub hadoopget($$$) {
	my ($fname, $url, $md5) = @_;
	if($url =~ /s3n?:\/\/[^\@]*$/ && defined($ENV{'AWS_SECRET_ACCESS_KEY'})) {
		my $ec2key = $ENV{'AWS_ACCESS_KEY_ID'}.":".$ENV{'AWS_SECRET_ACCESS_KEY'};
		$url =~ s/s3:\/\//s3:\/\/$ec2key\@/;
		$url =~ s/s3n:\/\//s3n:\/\/$ec2key\@/;
	}
	my $cmd = "$hadoop fs -get $url $fname";
	print STDERR "$cmd\n";
	my $rc = system ($cmd);
	die "hadoop get failed: $url $rc\n" if $rc;
}

## Download a file with s3cmd get
sub s3get($$$) {
	my ($fname, $url, $md5) = @_;
	$url = s3cmdify($url);
	my $cmd = "$s3cmd get $url $fname";
	print STDERR "$cmd\n";
	my $rc = system ($cmd);
	die "s3cmd get failed: $url $rc\n" if $rc;
}

## Fetch a file
sub fetch($$$)
{
	my ($fname, $url, $md5) = @_;

	print STDERR "Fetching $url $fname $md5\n";

	if ($url =~ /^hdfs:/)
	{
		hadoopget($fname, $url, $md5);
	}
	elsif ($url =~ /^s3n?:/)
	{
		s3get($fname, $url, $md5);
	}
	elsif ($url =~ /^ftp:/ || $url =~ /^https?:/)
	{
		wget($fname, $url, $md5);
	}
	elsif ($url ne $fname)
	{
		my $cmd = "cp $url ./$fname";
		print "$cmd\n";
		system($cmd);
	}

	if ($md5 ne "0")
	{
		my $omd5 = `md5sum $fname | cut -d' ' -f 1`;
		chomp($omd5);
		$omd5 eq $md5 || die "MD5 mismatch for file $fname; expected \"$md5\", got \"$omd5\"";
	}

	print STDERR "reporter:counter:Crossbow Bulk Copy,Read data fetched to EC2,".(-s $fname)."\n";

	if($fname =~ /\.gz$/) {
		my $cmd = "gunzip $fname >/dev/null";
		print "$cmd\n";
		system($cmd) == 0 || die "Error while gunzipping $fname";
		$fname =~ s/\.gz$//;
		print STDERR "reporter:counter:Crossbow Bulk Copy,Read data fetched to EC2 (uncompressed),".(-s $fname)."\n";
	}
}

##
# Handle the copy for a single unpaired entry
#
sub doUnpairedUrl($$) {
	my ($url, $md5) = @_;
	my @path = split /\//, $url;
	my $filename = $path[$#path];
	my $of;
	
	# fetch the file
	fetch($filename, $url, $md5);
	$filename =~ s/\.gz$//;
	
	# turn FASTQ entries into single-line reads
	open FILE, $filename || die "Could not open input file $filename";
	my $r = 0;
	my $fileno = 1;
	open $of, ">${filename}_$fileno.out";
	while(<FILE>) {
		my $name = $_;
		my $seq = <FILE>; chomp($seq);
		my $name2 = <FILE>;
		my $qual = <FILE>; chomp($qual);
		print $of "r\t$seq\t$qual\n";
		$r++;
		if($maxPerFile > 0 && ($r % $maxPerFile) == 0) {
			close($of);
			if($push ne "") {
				pushS3("${filename}_$fileno.out");
				system("rm -f ${filename}_$fileno.out ${filename}_$fileno.out.*");
			}
			$fileno++;
			open $of, ">${filename}_$fileno.out" || die;
		}
		$unpaired++;
		last if($r == $stopAfter);
	}
	close(FILE);
	close($of);

	# Remove input file
	system("rm -f $filename");
	if($push ne "") {
		# Push and remove output files
		pushS3("${filename}_$fileno.out");
		system("rm -f ${filename}_$fileno.out ${filename}_$fileno.out.*");
	} else {
		# Just keep the output files around
	}
}

##
# Handle the copy for a single paired entry
#
sub doPairedUrl($$$$) {
	my ($url1, $md51, $url2, $md52) = @_;
	my @path1 = split /\//, $url1;
	my @path2 = split /\//, $url2;
	my $filename1 = $path1[$#path1];
	my $filename2 = $path2[$#path2];
	fetch($filename1, $url1, $md51);
	fetch($filename2, $url2, $md52);
	$filename1 =~ s/\.gz$//;
	$filename2 =~ s/\.gz$//;
	
	# turn FASTQ pairs into tuples 
	open FILE1, $filename1 || die "Could not open input file $filename1";
	open FILE2, $filename2 || die "Could not open input file $filename2";
	my $r = 0;
	my $fileno = 1;
	my $of;
	open $of, ">${filename1}_$fileno.out" || die;
	while(<FILE1>) {
		my $name1 = $_;
		my $seq1 = <FILE1>; chomp($seq1);
		my $name1tmp = <FILE1>;
		my $qual1 = <FILE1>; chomp($qual1);
		
		my $name2 = <FILE2>;
		my $seq2 = <FILE2>; chomp($seq2);
		my $name2tmp = <FILE2>;
		my $qual2 = <FILE2>; chomp($qual2);
		(defined($seq1) && defined($qual1) && defined($seq2) && defined($qual2))
			|| die "Mate files did not come together properly";
		print $of "r\t$seq1\t$qual1\t$seq2\t$qual2\n";
		$r++;
		if($maxPerFile > 0 && ($r % $maxPerFile) == 0) {
			close($of);
			if($push ne "") {
				pushS3("${filename1}_$fileno.out");
				system("rm -f ${filename1}_$fileno.out ${filename1}_$fileno.out.*");
			}
			$fileno++;
			open $of, ">${filename1}_$fileno.out" || die;
		}
		$paired++;
		last if($r == $stopAfter/2);
	}
	close(FILE1);
	close(FILE2);
	close($of);

	# Remove input files
	system("rm -f $filename1 $filename2");
	if($push ne "") {
		# Push and remove output files
		pushS3("${filename1}_$fileno.out");
		system("rm -f ${filename1}_$fileno.out ${filename1}_$fileno.out.*");
	} else {
		# Just keep the output files around
	}
}

##
# Add user's credentials to an s3 or s3n URI if necessary
#
sub addkey($) {
	my $url = shift;
	if($url =~ /s3n?:\/\/[^\@]*$/ && defined($ENV{'AWS_SECRET_ACCESS_KEY'})) {
		my $ec2key = $ENV{'AWS_ACCESS_KEY_ID'}.":".$ENV{'AWS_SECRET_ACCESS_KEY'};
		$url =~ s/s3:\/\//s3:\/\/$ec2key\@/;
		$url =~ s/s3n:\/\//s3n:\/\/$ec2key\@/;
	}
	return $url;
}

while (<>) {
	# Skip comments and whitespace lines
	chomp;
	my @s = split(/\s+/);
	if ($skipfirst) { shift @s; }
	next if scalar(@s) == 0; # Skip empty or whitespace-only lines
	next if $s[0] =~ /^\#/;  # Skip lines beginning with hash

	my ($url1, $md51) = (addkey($s[0]), $s[1]);

	if($#s == 3) {
		my ($url2, $md52) = (addkey($s[2]), $s[3]);
		doPairedUrl($url1, $md51, $url2, $md52);
	} else {
		doUnpairedUrl($url1, $md51);
	}
	print STDERR "reporter:counter:Crossbow Bulk Copy,Unpaired reads,$unpaired\n";
	print STDERR "reporter:counter:Crossbow Bulk Copy,Paired-end reads,$paired\n";
}
