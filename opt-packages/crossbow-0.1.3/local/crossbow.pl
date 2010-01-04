#!/usr/bin/perl -w
use strict;
use Getopt::Long;

## Run script for running Crossbow on a (local) Hadoop cluster
##
## Preparation (not done with this script)
## 1. Upload reference data to hdfs into index directory.
##    See Crossbow manual for details on these files, but it
##    is not necessary to store the files in a jar. Instead all
##    files should be stored in a single directory.
##    $ hadoop fs -mkdir /users/mschatz/human/index
##    $ hadoop fs -put index/* /users/mschatz/human/index
##    This directory should contain: chr*.fa, chr*.snp, index.*.ebwt
##
## 2. Upload reads
##    $ hadoop fs -mkdir /users/mschatz/human/reads
##    $ hadoop fs -put reads/* /users/mschatz/human/reads
##
## 3. Create read manifest file
##    Contains the full path (with hdfs://) to each read file, with mated files on same line:
##    hdfs://szhdname00:9000/users/mschatz/chr22/reads/sim_paired_1_1_1.fq.gz 0 hdfs://szhdname00:9000/users/mschatz/chr22/reads/sim_paired_1_1_2.fq.gz 0
##
## Run Crossbow
## 1. Preprocess reads 
##    $ crossbow.pl -pre -readlist /local/path/to/manifest human
##
## 2. Run Bowtie
##    $ crossbow.pl -bowtie human
##
## 3. Run SoapSNP      
##    $ crossbow.pl -snps -fetchsnps human
##
## After your run, crossbow will create a human.snps file on the local
## filesystem. See the crossbow manual for a description of the file 
## format

## System configuration parameters
## You must configure these for your environment
#################################################################

## Set as the URL for your hdfs
my $HDFSURL = "hdfs://szhdname00:9000";

## Path on local system to your hadoop command
my $HADOOP = "/opt/UMhadoop/bin/hadoop";

## Path on local system to your hadoop streaming jar, with version matching the hadoop command
my $STREAMING = "/opt/UMhadoop/contrib/streaming/hadoop-0.20.0-streaming.jar";

## Path on the local system to the crossbow preprocessor
my $preproc_path = "~mschatz/build/crossbow/ec2-master/copy_mapper.pl";

## Path of the local system to bowtie  (compiled for the for hadoop worker nodes)
my $bowtie_path  = "~mschatz/build/crossbow/cbcb/bowtie";

## Path on the local system to the soapsnp (compiled for the hadoop worker nodes)
my $soapsnp_path = "~mschatz/build/crossbow/soapsnp/soapsnp";

## Path on the local system to the soapsnp wrapper
my $sswrap_path  = "~mschatz/build/crossbow/ec2-master/soapsnp_wrap.pl";

## Path on the local system to the filter script
my $filter_path  = "~mschatz/build/crossbow/cbcb/filter_alignments.pl";

my $owner = `whoami`;
chomp ($owner);

## Default hdfs base directory will be $hdfsbase/<PROJECT>/..., override with crossbow -base
my $hdfsbase     = "/users/$owner/";

## Number of reducers to use, typically the number of nodes in the cluster
my $numReducers = 20;


## Once your environment is configured, delete the following line
die "Edit crossbow.pl to configure\n";






## Default Run parameters
#################################################################

my $partition_size = 2000000;
my $insert_size = 500;

my $snp_diploid_args = "-r 0.00005 -e 0.0001 -K";
my $snp_haploid_args = "-r 0.0001 -K";
my $haploid = undef;

my $fchr   = undef;
my $fstart = undef;
my $fend   = undef;
my $fpos   = undef;

my $readlist; 

my $verbose = 0;
my $fetch_snps = 0;
my $fetch_alignments = 0;
my $fetch_filtered = 0;

my $runPreproc  = 0;
my $runBowtie   = 0;
my $runSoapsnp  = 0;
my $runFilter   = 0;
my $runAlignSnp = 0;
my $dryrun = 0;




## Process the command line arguments
#################################################################

my $argsstr = join(" ", @ARGV);

my $helpflag = 0;
my $result = GetOptions(
 "h"              => \$helpflag,
 "verbose"        => \$verbose,
 "dryrun"         => \$dryrun,
 "base=s"         => \$hdfsbase,
 "numReducers=s"  => \$numReducers,

 "pre"            => \$runPreproc,
 "readlist=s"     => \$readlist,

 "alignsnp"       => \$runAlignSnp,

 "bowtie"         => \$runBowtie,
 "partition=s"    => \$partition_size,
 "fetchalign"     => \$fetch_alignments,


 "snps"           => \$runSoapsnp,
 "haploid=s"      => \$haploid,
 "haploid_args=s" => \$snp_haploid_args,
 "diploid_args=s" => \$snp_diploid_args,
 "fetchsnps"      => \$fetch_snps,

 "filter"         => \$runFilter,
 "fchr=s"         => \$fchr,
 "fstart=s"       => \$fstart,
 "fend=s"         => \$fend,
 "fpos=s"         => \$fpos,
 "fetchfiltered"  => \$fetch_filtered,
);

my $prefix = shift @ARGV;
my $err = 0;

if (!defined $prefix)
{
  print "ERROR: You must specify a prefix\n";
  $err++;
}

if (!$runPreproc && 
    !$runBowtie && 
    !$runSoapsnp &&
    !$runFilter &&
    !$runAlignSnp &&
    !$fetch_snps &&
    !$fetch_filtered &&
    !$fetch_alignments &&
    !$helpflag)
{
  print "ERROR: No operation specified\n";
  $helpflag = 1;
}

if ($runPreproc)
{
  if (!defined $readlist)
  {
    print "ERROR: You must specify a readlist\n";
    $err++;
  }
}

if ($runFilter)
{
  if (defined $fpos)
  {
    $fstart = $fpos;
    $fend = $fpos;
  }

  if (!defined $fchr || 
      !defined $fstart ||
      !defined $fend)
  {
    print "ERROR: Filtering chromsome position or range must be specified\n";
    $err++;
  }
}

if ($runAlignSnp)
{
  if ($runBowtie)
  {
    print STDERR "WARNING: alignsnp specified, not separately running bowtie\n";
    $runBowtie = 0;
  }

  if ($runSoapsnp)
  {
    print STDERR "WARNING: alignsnp specified, not separately running soapsnp\n";
    $runSoapsnp = 0;
  }
}


if ($helpflag)
{
  print "Usage: crossbow.pl [-pre|-bowtie|-snps|-filter] [options] prefix\n";
  print "Operations:\n";
  print "-pre Preprocess: Download and format reads\n";
  print "   -readlist <file> Local filename with list of reads and mates\n";
  print "\n";
  print "-alignsnp Bowtie & Soapsnp\n";
  print "   (see below)\n";
  print "\n";
  print "-bowtie  Bowtie: Align reads to reference\n";
  print "   -partition <int> partition size (default $partition_size)\n";
  print "   -fetchalign      Fetch alignments to local disk\n";
  print "\n";
  print "-snps    SoapSNP: Call SNPs\n";
  print "   -haploid <str>      List of haploid chromosomes\n";
  print "   -haploid_args <str> Additional haploid args (default: $snp_haploid_args)\n";
  print "   -diploid_args <str> Additional diploid args (default: $snp_diploid_args)\n";
  print "   -partition <int>    Partition size (default $partition_size)\n";
  print "   -fetchsnps          Fetch snps to local disk\n";
  print "\n";
  print "-filter  Filter: Find alignments in a specified region\n";
  print "   -fchr   <id>  Filter this chromsome\n";
  print "   -fpos   <int> Filter around this position\n";
  print "   -fstart <int> Filter start position\n";
  print "   -fend   <int> Filter end position\n";
  print "   -fetchfilter  Fetch filtered alignments to local disk\n";
  print "\n";
  print "Global Options:\n";
  print "  -base <dir> Base hdfs directory (default: $hdfsbase)\n";
  print "  -numReducers <int> Number of reducers (default: $numReducers)\n";
  print "  -verbose    Verbose mode\n";
  print "  -dryrun     Dry run\n";

  exit 0;
}

if ($err)
{
  exit 1;
}



## Setup variables
#################################################################

if (defined $haploid) { $haploid = "--haploids $haploid"; }
else                  { $haploid = ""; }

my $bowtie_cmd = "\"./bowtie index/index -p 2 --partition $partition_size -X $insert_size -m 1 -v 2 --best --strata --mm --12 - --startverbose --mmsweep\"";
my $snp_cmd    = "\"sh -c \'chmod +x soapsnp_wrap.pl && ./soapsnp_wrap.pl --soapsnp=./soapsnp --haploid_args=\\\"$snp_haploid_args\\\" --diploid_args=\\\"$snp_diploid_args\\\" --refdir=index --snpdir=index --partition=$partition_size $haploid\'\"";

$hdfsbase .= "/$prefix";

my $readdir   = "$hdfsbase/reads";
my $indexdir  = "$hdfsbase/index";
my $predir    = "$hdfsbase/preproc";
my $aligndir  = "$hdfsbase/align";
my $snpsdir   = "$hdfsbase/snps";
my $filterdir = "$hdfsbase/filter";

my $STARTTIME = time;
print STDERR "Running: crossbow.pl $argsstr\n\n";


### HDFS Helpers
#################################################################

sub hdfs_exists
{
  my $path = shift;
  my $rc = system("($HADOOP fs -stat $path) >& /dev/null");

  return !$rc;
}

sub hdfs_remove
{
  my $path = shift;
  if (hdfs_exists($path))
  {
    my $rc = system("$HADOOP fs -rmr $path");
    if ($rc)
    {
      die "ERROR: Couldn't delete old file $path\n";
    }
  }
}

sub hdfs_require
{
  my $path = shift;
  my $exists = hdfs_exists($path);

  if (!$exists)
  {
    die "ERROR: Can't find required file $path\n";
  }
}

sub hdfs_fetch
{
  my $path = shift;
  my $file = shift;
  my $merge = shift;

  my @vals = split /\//, $path;

  my $dir = pop @vals;

  if (-e $file)
  {
    print "WARNING: removing local $file\n";
    system("rm -rf $file"); 
  }
  
  print "Fetching $path to $file\n";

  if ($merge)
  {
    system("$HADOOP fs -getmerge $path $file");
  }
  else
  {
    system("$HADOOP fs -get $path $file");
  }
}

sub hdfs_put
{
  my $src = shift;
  my $dst = shift;

  if (hdfs_exists($dst))
  {
    print "WARNING: replacing old $dst from hdfs\n";
    system("$HADOOP fs -rmr $dst");
  }

  my $rc = system("$HADOOP fs -put $src $dst");
  die "Can't load $src to $dst ($rc)\n" if $rc;
}



### Helpers

sub runCmd
{
  my $cmd = shift;
  my $desc = shift;

  my $jobstarttime = time;

  print "Running $desc... \n";
  print "  $cmd\n" if $verbose;
  system($cmd) if (!$dryrun);

  my $jobendtime = time;
  my $duration = $jobendtime - $jobstarttime;

  print "== DURATION $desc = $duration\n";
  print "\n";
}




## Preprocessor
#################################################################

if ($runPreproc)
{
  ## Count pe and se files, make sure they have unique names
  open READLIST, "< $readlist" or die "Can't open $readlist ($!)\n";

  my $se = 0;
  my $pe = 0;
  my %files;
  while (<READLIST>)
  {
    chomp;
    my @vals = split /\s+/, $_;

    if    (scalar @vals == 2) { $se++;  }
    elsif (scalar @vals == 4) { $pe+=2; }
    else
    {
      die "ERROR: Malformed read file: $_\n";
    }

    while (scalar @vals)
    {
      my $url = shift @vals;
      my $md5 = shift @vals;

      my @path = split /\//, $url;
      my $file = pop @path;

      die "ERROR: $file is present multiple times\n"
        if (exists $files{$file});

      $files{$file} = 1;
    }
  }

  print "Preprocessing $se single-end and $pe paired-end files\n";

  hdfs_put($readlist, "$hdfsbase/$prefix.readlist");

  hdfs_remove($predir);
  hdfs_remove("$predir.log");

  my $cmd = "$HADOOP jar $STREAMING"
            . " -D mapred.job.name=\'Crossbow Preprocessor $prefix\'"
            . " -file $preproc_path"
            . " -input $hdfsbase/$prefix.readlist"
            . " -inputformat org.apache.hadoop.mapred.lib.NLineInputFormat"
            . " -output $predir.log"
            . " -mapper \"./copy_mapper.pl -s -owner $owner -push $HDFSURL/$predir -hadoop $HADOOP -compress none\"" 
            . " -numReduceTasks 0";
  runCmd($cmd, "Preprocessor");
}

## Align and Call SNPs
#################################################################


if ($runAlignSnp)
{
  hdfs_require($predir);
  hdfs_require($indexdir);
  hdfs_remove($snpsdir);

  my $cmd = "$HADOOP jar $STREAMING"
            . " -D mapred.job.name=\'Crossbow Bowtie and SoapSNP $prefix\'"
            . " -D mapred.text.key.partitioner.options=-k1,2"
            . " -D stream.num.map.output.key.fields=3"
            . " -files \"$HDFSURL/$indexdir\""
            . " -partitioner org.apache.hadoop.mapred.lib.KeyFieldBasedPartitioner"
            . " -file $bowtie_path"
            . " -file $soapsnp_path"
            . " -file $sswrap_path"
            . " -input $predir"
            . " -output $snpsdir"
            . " -mapper $bowtie_cmd"
            . " -reducer $snp_cmd"
            . " -numReduceTasks $numReducers";

  runCmd($cmd, "Bowtie and SoapSNP");
}



## Bowtie Alignment
#################################################################

if ($runBowtie)
{
  hdfs_require($predir);
  hdfs_require($indexdir);
  hdfs_remove($aligndir);

  my $cmd = "$HADOOP jar $STREAMING"
            . " -D mapred.job.name=\'Crossbow Bowtie $prefix\'"
            . " -files \"$HDFSURL/$indexdir\""
            . " -file $bowtie_path"
            . " -input $predir"
            . " -output $aligndir"
            . " -mapper $bowtie_cmd"
            . " -numReduceTasks 0";
  runCmd($cmd, "Bowtie");
}


## SoapSNP
#################################################################

if ($runSoapsnp)
{
  hdfs_require($aligndir);
  hdfs_remove($snpsdir);

  my $cmd = "$HADOOP jar $STREAMING"
            . " -files \"$HDFSURL/$indexdir\"" 
            . " -D mapred.job.name=\'Crossbow Sort and SoapSNP $prefix\'"
            . " -D mapred.text.key.partitioner.options=-k1,2"
            . " -D stream.num.map.output.key.fields=3"
            . " -partitioner org.apache.hadoop.mapred.lib.KeyFieldBasedPartitioner"
            . " -input $aligndir"
            . " -output $snpsdir"
            . " -file $soapsnp_path"
            . " -file $sswrap_path"
            . " -mapper cat"
            . " -reducer $snp_cmd"
            . " -numReduceTasks $numReducers";

  runCmd($cmd, "SoapSNP");
}


## Alignment Filtering
#################################################################

if ($runFilter)
{
  hdfs_remove($filterdir);

  my $cmd = "$HADOOP jar $STREAMING"
            . " -D mapred.job.name=\"Filter Alignments $fchr $fstart $fend\""
            . " -input $aligndir"
            . " -output $filterdir"
            . " -file $filter_path"
            . " -mapper \"./filter_alignments.pl $fchr $fstart $fend\""
            . " -numReduceTasks 1";
  runCmd($cmd, "Filter Alignments");
}


hdfs_fetch($aligndir, "$prefix.align", 0) if $fetch_alignments;
hdfs_fetch($snpsdir, "$prefix.snps", 1) if $fetch_snps;
hdfs_fetch($filterdir, "$prefix.$fchr.$fstart.$fend.aligns", 1) if $fetch_filtered;


my $ENDTIME = time;
my $diff = $ENDTIME - $STARTTIME;
print "Total runtime: $diff\n";
