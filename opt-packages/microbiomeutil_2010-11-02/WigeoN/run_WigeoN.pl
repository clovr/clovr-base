#!/usr/bin/env perl

use strict;
use warnings;

use Carp;
use Getopt::Long qw(:config no_ignore_case bundling);
use FindBin;

use lib ("$FindBin::Bin/PerlLib");
use Fasta_reader;
use CdbTools;


my $refDB = "$FindBin::Bin/../RESOURCES/rRNA16S.gold.fasta";
my $refNAST =  "$FindBin::Bin/../RESOURCES/rRNA16S.gold.NAST_ALIGNED.fasta";

my $usage = <<__EOUSAGE__;

##################################################################
#  Required:
#  --query_NAST   multi-fasta file containing query sequences in alignment format
#
# Optional:
#
#  --db_NAST       db in NAST format
#  --db_FASTA      db in fasta format (megablast formatted)
#
#  --num_top_hits    default 1: uses only the single best match.
#
#  --plot
#  --DEBUG
#  --exec_dir       cd to exec_dir before running
##################################################################

__EOUSAGE__

	;


my $help_flag;
my $queryNAST;

my $num_top_hits = 1;
my $VERBOSE = 0;
my $PLOT = 0;
my $DEBUG = 0;
my $exec_dir;

&GetOptions ( 'h' => \$help_flag,
			  'query_NAST=s' => \$queryNAST,
			  'db_NAST=s' => \$refNAST,
			  'db_FASTA=s' => \$refDB,
			  'num_top_hits=i' => \$num_top_hits,
			  'V' => \$VERBOSE,
			  'plot' => \$PLOT,
			  'DEBUG' => \$DEBUG,
			  'exec_dir=s' => \$exec_dir,
	);


if ($help_flag) { die $usage; }

unless ($queryNAST) {
	die $usage;
}


main: {
	
	if ($exec_dir) {
		chdir($exec_dir) or die "Error, cannot cd to $exec_dir";
	}
	
	my $tmp_query = "/tmp/tmp.$$.q";
	my $tmp_ref = "/tmp/tmp.$$.r";

	my $fastaReader = new Fasta_reader($queryNAST);
	while (my $seq_obj = $fastaReader->next()) {
		
		my $acc = $seq_obj->get_accession();
		
		$seq_obj->write_fasta_file($tmp_query);
			
		my @top_hit_accs = &get_top_blast_hit($seq_obj->get_accession(), $seq_obj->get_sequence());
				
		unless (@top_hit_accs) {
			print "$acc\tNA\tdiv:\tNA\tstDev: NA\tUNKNOWN\n";
			next;
		}

		foreach my $top_hit (@top_hit_accs) {
			
			my $fasta_entry = &cdbyank($top_hit, $refNAST);
			open (my $ofh, ">$tmp_ref") or die "Error, cannot write to $tmp_ref";
			print $ofh $fasta_entry;
			close $ofh;
			
			## run WigeonN
			my $cmd = "$FindBin::Bin/WigeoN.pl -Q $tmp_query -R $tmp_ref -P $FindBin::Bin/data/rRNA16S.gold.NAST_ALIGNED.fasta.cons -M $FindBin::Bin/data/eco.prokMSA ";
			
			if ($PLOT) {
				$cmd .= " --plot ";
			}

			if ($DEBUG) {
				$cmd .= " --DEBUG ";
			}
			
			
			print STDERR "$cmd\n" if $VERBOSE;
			my $result = `$cmd`;
			
			if ($?) {
				print STDERR "Error, cmd $cmd died with ret $?";
				print "$acc\t$top_hit\tdiv:\tNA\tstDev: NA\tUNKNOWN\n";
				next;
			}
			print $result;
		}
	}
	
	unlink($tmp_query, $tmp_ref);

	exit(0);
}

####
sub get_top_hits {
	my ($file) = @_;
	
	my %hits;
	
	open (my $fh, $file) or die "Error, cannot open file $file";
	while (<$fh>) {
		chomp;
		
		my @x = split (/\t/);
		my ($accA, $accB) = ($x[0], $x[1]);
		if ($accA eq $accB) { next; }
		
		my $num_hits = 0;
		if (exists $hits{$accA} ) {
			my @curr_hits = keys %{$hits{$accA}};
			$num_hits = scalar(@curr_hits);
		}
		if ($num_hits < $num_top_hits) {
			$hits{$accA}->{$accB} = 1;
		}
	}

	my %ret;
	foreach my $acc (keys %hits) {
		my @other_accs = keys %{$hits{$acc}};
		$ret{$acc} = [@other_accs];
	}

	return(%ret);
	
}

####
sub get_top_blast_hit {
	my ($acc, $sequence) = @_;

	unless (-e "$refDB.nin") {
		## make database blastable
		my $cmd = "formatdb -i $refDB -p F";
		system($cmd);
	}

	
	$sequence =~ s/[\.\-]//g;
	my $tmpfile = "/tmp/tmp.$$.blq";
	open (my $ofh, ">$tmpfile") or die $!;
	print $ofh ">q\n$sequence\n";
	close $ofh;
	
	## run blast;
	#my $cmd = "blastn $refDB $tmpfile V=1 B=1 -mformat=2 -cpus=1 -novalidctxok ";
	
	my $search_top_hits = $num_top_hits + 1; # in case doing a self-db search, avoid self hits.

	my $cmd = "megablast -d $refDB -i $tmpfile -v $search_top_hits -b $search_top_hits -m 8 ";
	
	my $result = `$cmd`;
	unlink($tmpfile);
	if ($?) {
	    print STDERR "Error, cmd $cmd died with $?";
		return();
	}
	
	my %hits;
	
	my $count = 0;
	foreach my $line (split (/\n/, $result)) {
		#print "$line\n";
		my @x = split (/\t/, $line);
		$x[1] =~ s/\#.*$//; 
		
		# no self hits!!!
		if ($x[1] eq $acc) { next; }
		
		if (scalar(keys %hits) >= $num_top_hits) {
			last;
		}
		$hits{$x[1]} = ++$count;
		
	
	}
	
	my @hits = sort {$hits{$a}<=>$hits{$b}} keys %hits; # keep hits in order
	
	return(@hits);
	
}
