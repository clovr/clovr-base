#!/usr/bin/perl -w

##
# soapsnp_wrap.pl
#
#  Authors: Ben Langmead & Michael C. Schatz
#     Date: June 2009
#

use strict;
use warnings;
use Getopt::Long;

my $plen = 2000000;
my $args = "";
my $refdir = ".";
my $snpdir = ".";
my $soapsnp = "./soapsnp";
my $haploidstr = "";
my $dryRun = 0;
my $maxlen = 45;
my $baseQual = '!';
my $diploid_args = "-r 0.00005 -e 0.0001";
my $haploid_args = "-r 0.0001";

my $result = GetOptions (
    "soapsnp=s"      => \$soapsnp,
    "refdir=s"       => \$refdir,
    "snpdir=s"       => \$snpdir,
    "maxlen=i"       => \$maxlen,
    "partition=i"    => \$plen,
    "args=s"         => \$args,
    "diploid_args=s" => \$diploid_args,
    "haploid_args=s" => \$haploid_args,
    "haploids=s"     => \$haploidstr,
    "dryrun"         => \$dryRun,
    "basequal=s"     => \$baseQual);

$haploid_args .= " -m";

chmod 0777, $soapsnp;

my $deletedShared = 0;

# Remove leftover shared memory from map step
sub deleteSharedMem {
	print STDERR "\n";
	print STDERR "Shared memory prior:\n";
	print STDERR `ipcs -a`;
	my $shmemcmd = "ipcs | grep root | awk '{print \$1}' | xargs -n 1 ipcrm -M >/dev/null 2>/dev/null";
	print STDERR "Removing shared memory\n$shmemcmd\n";
	system($shmemcmd);
	print STDERR "Shared memory after:\n";
	print STDERR `ipcs -a`;
	print STDERR "\n";
}

print STDERR "soapsnp binary: $soapsnp\n";
print STDERR "refdir: $refdir\n";
print STDERR "snpdir: $snpdir\n";
print STDERR "partition length: $plen\n";
print STDERR "soapsnp args: $args\n";
print STDERR "haploid ids: $haploidstr\n";
print STDERR "haploid arguments: $haploid_args\n";
print STDERR "diploid arguments: $diploid_args\n";
print STDERR "maximum read length: $maxlen\n";
print STDERR "base quality value: $baseQual\n";
print STDERR "dryrun: $dryRun\n";

my $lchr = -1;
my $lpart = -1;
my $als = 0;

# Record which chromosomes are haploid; assume all others are diploid
my %hapHash = ();
my @haploids = split /[,]/, $haploidstr;
for my $h (@haploids) { $hapHash{$h} = 1; }

open TMP, ">.tmp.$plen.0" || die;
while(1) {
	# Extract the chromosome and partition key
	my $line = <>;
	next if defined($line) && substr($line, 0, 1) eq '#';
	my $chromo;
	my $parti;
	if(defined($line)) {
		# Parse chromosome and partition for this alignment
		my $spidx = index($line, "\t");
		my $tidx = index($line, "\t", $spidx+1);
		$chromo = substr($line, 0, $spidx);
		$parti = substr($line, $spidx+1, ($tidx-($spidx+1)));
	} else {
		# No more input; last partition was final
		last if $als == 0; # bail if there are no alignments to flush
		$parti = $lpart+1; # force alignments to flush
	}
	# If either the partition or the chromosome is different...
	if($parti != $lpart || $chromo != $lchr) {
		close(TMP);
		# If there are any alignments to flush...
		if($als > 0) {
			#
			# Set up range based on partition id and partition length
			#
			my $irange = $plen * int($lpart);
			my $frange = $irange + $plen;
			my $rname = ".range_".$irange."_$frange";
			open RANGE, ">$rname" || die;
			print RANGE "$lchr\t$irange\t$frange\n";
			close(RANGE);
			
			print STDERR "reporter:counter:SoapSNP,Ranges processed,1\n";
			print STDERR "reporter:counter:SoapSNP,Alignments processed,$als\n";
			
			unless($deletedShared) {
				deleteSharedMem();
				$deletedShared = 1;
			}
			
			#
			# Run SOAPsnp
			#
			my $date = `date`;
			print STDERR "Genotyping chromosome $lchr $irange-$frange using $als alignments: $date";
			my $ploid = $diploid_args;
			if(defined($hapHash{$lchr})) {
				print STDERR "  chromosome $lchr is haploid; using args \"$haploid_args\"\n";
				$ploid = $haploid_args;
			} else {
				print STDERR "  chromosome $lchr is diploid; using args \"$diploid_args\"\n";
			}
			
			print STDERR "head -4 .tmp.$plen.$lpart:\n";
			print STDERR `head -4 .tmp.$plen.$lpart`;
			print STDERR "tail -4 .tmp.$plen.$lpart:\n";
			print STDERR `tail -4 .tmp.$plen.$lpart`;
			
			my $cmd = "${soapsnp} ".
			          "-i .tmp.$plen.$lpart ". # alignments
			          "-d $refdir/chr$lchr.fa ". # reference sequence
			          "-o .tmp.snps ". # output file
			          "-s $snpdir/chr$lchr.snps ". # known SNP file
			          "-z '$baseQual' ". # base quality value
			          "-L $maxlen ". # maximum read length
			          "-c ". # Crossbow
			          "-T $rname ". # region
			          "$ploid ". # ploidy/rate args
			          "$args ". # other arguments
			          ">.soapsnp.$$.stdout ".
			          "2>.soapsnp.$$.stderr";
			print STDERR "$cmd\n";

			my $ret = $dryRun ? 0 : system($cmd);

			print STDERR "soapsnp returned $ret\n";
			print STDERR "command: $cmd\n";
			open OUT, ".soapsnp.$$.stdout";
			print STDERR "stdout from soapsnp:\n";
			while(<OUT>) { print STDERR $_; } close(OUT);
			open ERR, ".soapsnp.$$.stderr";
			print STDERR "stderr from soapsnp:\n";
			while(<ERR>) { print STDERR $_; } close(ERR);
			print STDERR "range: $lchr\t$irange\t$frange\n";

			print STDERR "head -4 .tmp.snps:\n";
			print STDERR `head -4 .tmp.snps`;
			print STDERR "tail -4 .tmp.snps:\n";
			print STDERR `tail -4 .tmp.snps`;

			die "Dying following soapsnp returning non-zero $ret" if $ret;
			
			#
			# Read and print called SNPs
			#
			$als = 0;

			my $snpsreported = 0;
			open SNPS, ".tmp.snps";
			while(<SNPS>) {
				my @ss = split;
				my $snpoff = ($ss[0] eq 'K' ? $ss[2] : $ss[1]);
				$snpoff == int($snpoff) || die "SNP offset isn't a number: $snpoff";
				if($snpoff < $irange || $snpoff >= $frange) {
					print STDERR "Skipping $snpoff because it's outside [$irange, $frange) $_\n";
					next;
				}
				print $_;
				$snpsreported++;
			}
			close(SNPS);
			print STDERR "reporter:counter:SoapSNP,SNPs reported,$snpsreported\n";
			print STDERR "Reported $snpsreported SNPs\n";
		}
		open TMP, ">.tmp.$plen.$parti" || die;
		$lpart = $parti;
		$lchr = $chromo;
	}
	last unless defined($line);
	print TMP "$line";
	$als++;
}
close(TMP);
