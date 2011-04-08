#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

use FindBin;
use lib ("$FindBin::Bin/PerlLib");
use Fasta_reader;
use CdbTools;
use Nuc_translator;


my $db_FASTA = "$FindBin::Bin/..//RESOURCES/rRNA16S.gold.fasta";
my $db_NAST = "$FindBin::Bin/../RESOURCES/rRNA16S.gold.NAST_ALIGNED.fasta";


my $usage = <<_EOUSAGE_;

###########################################################################
#
#
#  Required:
#
#  --query_FASTA     query database in FASTA format (seqs to NAST-align)
#
#  Optional: (unless defaults are not set!)
#
#  --db_NAST         reference database in NAST format (default: $db_NAST)
#
#  --db_FASTA        reference database in FASTA format (default: $db_FASTA)
#
#  --num_top_hits    number of top hits to use for profile-alignment (default: 10)
#
#  --Evalue          Evalue cutoff for top hits (default: 1e-50)
#
############################################################################

_EOUSAGE_

	;


my $num_top_hits = 10;
my $Evalue = 1e-50;
my $queryFasta;

my $percent_top_blast_score = 80;

my $verbose = 0;

&GetOptions ("query_FASTA=s" => \$queryFasta,
			 "db_NAST=s" => \$db_NAST,
			 "db_FASTA=s" => \$db_FASTA,
			 "num_top_hits=i" => \$num_top_hits,
			 "Evalue=f" => \$Evalue,

			 "v" => \$verbose,


	);

			 
unless ($queryFasta) {
	die $usage;
}



####
main: {
	
	## ensure megablast-ready
	unless (-e "$db_FASTA.nin") {
		my $cmd = "formatdb -i $db_FASTA -p F 2>/dev/null ";
		my $ret = system($cmd);
		if ($ret) {
			die "Error, couldn't format $db_FASTA for use with megablast\n$cmd died with ret($ret) ";
		}
	}
	
	## process each query sequence in order
	my $fasta_reader = new Fasta_reader($queryFasta);
	
	while (my $seq_obj = $fasta_reader->next()) {
		
		my $acc = $seq_obj->get_accession();
		my $sequence = $seq_obj->get_sequence();
		$sequence =~ s/[\.\-]//g;
		
		my $tmp_query = "/tmp/$$.query";
		{
			open (my $fh, ">$tmp_query") or die "Error, cannot write to $tmp_query";
			print $fh ">$acc\n$sequence\n";
			close $fh;
		}
		
		
		## blast the core, get the top 10 hits
		#my $cmd = "blastn $GGenes_Core_unaligned $tmp_query E=1e-10 V=$num_top_hits B=$num_top_hits -mformat=2 -wordmask=dust -cpus=1 ";
		
		my $cmd = "megablast -d $db_FASTA -i $tmp_query -e $Evalue -m 8 -v $num_top_hits -b $num_top_hits 2>/dev/null";
		#print "CMD: $cmd\n";
		my @hits = `$cmd`;



		if ($?) {
			print STDERR "ERROR, Blast search failed!  Skipping entry $acc\n\n";
			next;
		}

		if ($verbose) {
			print "MEGABLAST for $acc:\n";
			print join("\n", @hits) . "\n";
		}

		
		my @seqs;
		my %seen;
		my $orient;

		my $top_blast_score = undef;

		foreach my $hit (@hits) {
			
			my @x = split (/\t/, $hit);
			my $hit_acc = $x[1];

			# weird megablast thing that extends the accession beyond first ws char for some reason... not sure.
			$hit_acc =~ s/\#.*//;
			
			my ($query_end5, $query_end3) = ($x[6], $x[7]);
			my ($hit_end5, $hit_end3) = ($x[8], $x[9]);
			my $query_orient = ($query_end5 < $query_end3) ? '+' : '-';
			my $hit_orient = ($hit_end5 < $hit_end3) ? '+' : '-';
			
			my $align_orient = ($query_orient eq $hit_orient) ? '+' : '-';

			my $bit_score = $x[11];
			if (! defined ($top_blast_score)) {
				$top_blast_score = $bit_score;
			}
			else {
				if ($bit_score / $top_blast_score * 100 < $percent_top_blast_score) {
					next;
				}
			}
			
			if ($orient && $align_orient ne $orient) { 
				## retain consistent relationship between query orient and the db hit orients
				next;
			}
			elsif (! $orient) {
				$orient = $align_orient;
			}
			
			unless ($seen{$hit_acc}) {
				$seen{$hit_acc} = 1;
				my $fasta_entry = &cdbyank($hit_acc, $db_NAST);
				push (@seqs, $fasta_entry);
			}
			
		}

		unless (@seqs) {
			print STDERR "Sorry, no blast hits reported.  Nothing to align to. Skipping accession $acc\n\n";
			next;
		}
		
		my $num_template_seqs = scalar(@seqs);
		print STDERR "Num template seqs to align to: $num_template_seqs\n";
		
		## extract NAST seqs for hit
		my $tmp_nast_in = "/tmp/$$.nastIn";
		{ 
			open (my $fh, ">$tmp_nast_in") or die "Error, cannot writ eto $tmp_nast_in";
			foreach my $seq (@seqs) {
				print $fh $seq . "\n";
			}
			close $fh;
		}

		if ($orient eq '-') {
			## put in forward orientation.
			$sequence = &reverse_complement($sequence); 
			open (my $fh, ">$tmp_query") or die "Error, cannot write to $tmp_query";
			print $fh ">$acc\n$sequence\n";
			close $fh;
		}
		
		## run NAST-iEr
		$cmd = "$FindBin::Bin/NAST-iEr $tmp_nast_in $tmp_query";
		my $ret = system $cmd;
		if ($ret) {
			die "Error, cmd $cmd died with ret $ret";
		}
		
		# cleanup
		unlink($tmp_query, $tmp_nast_in);
	}
	


	exit(0);
}
