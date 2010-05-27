#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

use lib ("/home/radon01/bhaas/EUK_modules");
use Fasta_reader;
use CdbTools;
use FindBin;

my $usage = <<_EOUSAGE_;

##########################################################################################
#
#  Required:
#    --query_NAST      multi-fasta file containing query sequences in alignment format

#    --db_NAST        db in NAST format
#  
#  Provide list of top hits:
#    --db_top_hits     Kmer-rank top hits
#    or
#    --CM_output       output from running ChimeraMaligner (takes the top N sequence hits there, rather than redoign the blast searches)
#
#  Or, Blastn on the fly, searching each sequence half separately
#  
#   --db_FASTA
#
#
#  Optional:
#
#    --numSeqsCompare     number of top matching database sequences to compare to (default 10)
#    --mask               (eco or lane)
#
#  ## parameters to tune bellerophon to your liking:
#
#    --windowSize                default 300
#    --windowStep                default 10
#    --parentFragmentThreshold   min percent identity required in bellerophon sequence windows (default 90)
#    --divergenceRatioThreshold  min divergence ratio for chimera assignment (default 1)    
#
#   --IGNORE_ACCS                skip accessions in this list.
#########################################################################################

_EOUSAGE_
	
	;

## Resources:

## option processing
my ($queryNast, $db_top_hits, $dbNast);
my $prog = "$FindBin::Bin/BellerophonGG.pl";

my $numSeqsCompare = 10;

my $parentFragmentThreshold = 90;
my $divergence_ratio = 1;
my $windowSize;
my $windowStep;
my $specific_query = undef;
my $dbFasta;
my $mask;
my $ignore_accs_file;
my $CM_file;

&GetOptions ("query_Nast=s" => \$queryNast,
			 "db_top_hits=s" => \$db_top_hits,
			 "numSeqsCompare=s" => \$numSeqsCompare,
			 "db_NAST=s" => \$dbNast,
			 "db_FASTA=s" => \$dbFasta,
			 "CM_output=s" => \$CM_file,
			 			 
			 "parentFragmentThreshold=f" => \$parentFragmentThreshold,
			 "divergenceRatioThreshold=f" => \$divergence_ratio,
			 "windowSize=i" => \$windowSize,
			 "windowStep=i" => \$windowStep,
			 "Q=s" => \$specific_query,
			 "mask=s" => \$mask,
			 "IGNORE_ACCS=s" => \$ignore_accs_file,
	
	);

unless ($queryNast && $prog && $dbNast && ($db_top_hits || $dbFasta || $CM_file) ) { die $usage; }


main: {
		
	## get the top num hits for each sequence.
	my %chimera_to_top_hits;
	if ($db_top_hits) {
		%chimera_to_top_hits = &parse_top_hits($db_top_hits);
	}
	elsif ($CM_file) {
		%chimera_to_top_hits = &parse_hits_from_CM_file($CM_file);
	}
	
	my %ignore;
	if ($ignore_accs_file) {
		my @accs = `cat $ignore_accs_file`;
		chomp @accs;
		%ignore = map { + $_ => 1 } @accs;
	}
	
	my $fasta_reader = new Fasta_reader($queryNast);
	while (my $seq_obj = $fasta_reader->next()) {
		my $acc = $seq_obj->get_accession();
		my $seqlength = length($seq_obj->get_sequence());
		if ($seqlength == 0) {
			print "!!! ERROR, $acc has no NAST sequence.  Skipping.\n";
			print STDERR "!!! ERROR, $acc has no NAST sequence.  Skipping.\n";
			next;
		}
		

		if ($ignore{$acc}) { 
			print STDERR "ignoring acc $acc as specified\n";
			next; 
		}
		
		if ($specific_query && $acc ne $specific_query) { next; }

		print "\nQuery: $acc\n\n";
		
		my $fasta_format = $seq_obj->get_FASTA_format();
		my $query_sequence = $seq_obj->get_sequence();
		$query_sequence =~ s/[\.\-]//g;

		my $query_file = "tmp.$$.query";
		my $db_file = "tmp.$$.db";
		open (my $fh, ">$query_file") or die "Error, cannot write to $query_file ";
		print $fh $fasta_format;
		close $fh;
		
		my $top_hits;
		if (%chimera_to_top_hits) {
			$top_hits = $chimera_to_top_hits{$acc} or die "Error, no top hits for $acc ";
		}
		else {
			$top_hits = &blast_to_top_hits($acc, $query_sequence, $dbFasta);
		}
		
		open ($fh, ">$db_file") or die "Error, cannot write to $db_file";
		foreach my $hit_acc (split (/\s+/, $top_hits)) {
			my $nast = &cdbyank($hit_acc, $dbNast);
			print $fh $nast;
		}
		close $fh;
		
		eval {
			## run bellerophon
			my $cmd = "$prog -Q $query_file -R $db_file "
				. " --printAlignments ";
			
			if ($mask) {
				$cmd .= " -M $mask ";
			}
			
			if (defined $parentFragmentThreshold) {
				$cmd .= " --parentFragmentThreshold $parentFragmentThreshold ";
			}
			if (defined $divergence_ratio) {
				$cmd .= " --divergenceRatioThreshold $divergence_ratio ";
			}
			if (defined $windowSize) {
				$cmd .= " --winSize $windowSize ";
			}
			if (defined $windowStep) {
				$cmd .= " --winStep $windowStep ";
			}
			
						
			print "$cmd\n";
			my $ret = system $cmd;
			if ($ret) {
				die "Error, cmd: $cmd died with ret ($ret)";
			}
		};
		if ($@) {
			print STDERR "$acc failed:   $@\n\n";
			die;
		}
		
		unlink($query_file, $db_file);

		if ($specific_query) { last; }

	}
	
	exit(0);
}


#### 
sub parse_top_hits {
	my ($db_top_hits) = @_;

	my %chimera_to_top_hits;
	
	my %top_hit_counter;
	open (my $fh, $db_top_hits) or die "Error, cannot open file $db_top_hits";
	while (<$fh>) {
		chomp;
		unless (/\w/) { 
			next;
		}
		
		my ($chimera, $core, $kmer, $jaccard) = split (/\t/);
		if ($chimera eq $core) { next; }
		my $num_hits = ++$top_hit_counter{$chimera};
		if ($num_hits <= $numSeqsCompare) {
			if (exists $chimera_to_top_hits{$chimera}) {
				$chimera_to_top_hits{$chimera} .= " ";
			}
			$chimera_to_top_hits{$chimera} .= "$core";
		}
	}
	close $fh;
	print STDERR "done reading top hits.\n";

	return(%chimera_to_top_hits);
}

####
sub parse_hits_from_CM_file {
	my ($CM_file) = @_;

	my %acc_to_top_hits_left;
	my %acc_to_top_hits_right;
	

	open (my $fh, $CM_file) or die "Error, cannot open file $CM_file";
	while (my $line = <$fh>) {
		if ($line =~ /^Query: (\S+)/) {
			my $query_acc = $1;
			until ($line =~ /^Top hits Left/) {
				$line = <$fh>;
			}
			until (! $line) {
				$line = <$fh>;
				chomp $line;
				if ($line =~ /\w/) {
					push (@{$acc_to_top_hits_left{$query_acc}}, $line);
				}
			}
			$line = <$fh>;
			unless ($line =~ /^Top hits Right/) {
				die "Error parsing CM file ";
			}
			while ($line =~ /\w/) {
				$line = <$fh>;
				chomp $line;
				if ($line) {
					push (@{$acc_to_top_hits_right{$query_acc}}, $line);
				}
			}
			
		}
		
	}
	

	my %top_hits;
	
	foreach my $acc (keys %acc_to_top_hits_left) {
		
		my @top_hits_left;
		my @top_hits_right;

		if ($acc_to_top_hits_left{$acc}) {
			@top_hits_left = @{$acc_to_top_hits_left{$acc}};
		}
		if ($acc_to_top_hits_right{$acc}) {
			@top_hits_right = @{$acc_to_top_hits_right{$acc}};
		}
		
		my @merged = &merge_lists(\@top_hits_left, \@top_hits_right);
		
		if (scalar @merged > $numSeqsCompare) {
			@merged = @merged[0..$numSeqsCompare-1];
		}
	
		$top_hits{$acc} = join(" ", @merged);

	}

	
	return(%top_hits);
	
}


####
sub blast_to_top_hits {
	my ($acc, $query_seq, $dbFasta) = @_;

	my $length = length($query_seq);
	
	## search first 33% and last 33% of sequence.
	
	my $first_part = substr($query_seq, 0, int(0.33 * $length));
	
	my $second_part = substr($query_seq, int(0.66 * $length));
	
	my @top_hits_first = &blast_seq($acc, $first_part, $dbFasta);
	my @top_hits_second = &blast_seq($acc, $second_part, $dbFasta);
	
	print "Top hits Left:\n" . join ("\t\n", @top_hits_first) . "\n\n";
	
	print "Top hits Right:\n" . join ("\t\n", @top_hits_second) . "\n\n";


	my @merged_hits = &merge_hits(\@top_hits_first, \@top_hits_second);
	if (scalar(@merged_hits) > $numSeqsCompare) {
		@merged_hits = @merged_hits[0..$numSeqsCompare-1];
	}
	
	return (join (" ", @merged_hits));	
}


####
sub merge_hits {
	my ($list_A_aref, $list_B_aref) = @_;
	
	my @A = @$list_A_aref;
	my @B = @$list_B_aref;
	
	my %seen;
	my @merged;
	while (@A || @B) {
		if (@A) {
			my $entry = shift @A;
			if (! $seen{$entry}) {
				push (@merged, $entry);
				$seen{$entry} = 1;
			}
		}
		if (@B) {
			my $entry = shift @B;
			if (! $seen{$entry}) {
				push (@merged, $entry);
				$seen{$entry} = 1;
			}
		}
	}
	
	return(@merged);
}
	
####
sub blast_seq {
	my ($acc, $seq, $db) = @_;

	open (my $fh, ">tmp.$$.q") or die $!;
	print $fh ">$acc\n$seq\n";
	close $fh;
	
	my $cmd = "blastn $db ./tmp.$$.q E=1e-10 V=10 B=15 -mformat=2 -wordmask=dust -cpus=1 -novalidctxok 2>/dev/null";
	my @results = `$cmd`;
	
	if ($?) {
		die "Error, cmd $cmd died with ret $?";
	}

	my @top_hits;
	my %seen;
	foreach my $result (@results) {
		my @x = split (/\t/, $result);
		if ($x[0] eq $x[1]) { next; } # no same query as hit.
		my $acc = $x[1];
		if (! $seen{$acc}) {
			$seen{$acc} = 1;
			push (@top_hits, $acc);
		}
	}

	return(@top_hits);
}

####
sub merge_lists {
	my ($list_A_aref, $list_B_aref) = @_;

	my @listA = @$list_A_aref;

	my @listB = @$list_B_aref;

	my @merged;
	my %seen;
	
	while (@listA && @listB) {
		my $eleA = shift @listA;
		if (defined $eleA) {
			if (! $seen{$eleA}) {
				$seen{$eleA} = 1;
				push (@merged, $eleA);
			}
		}
		
		my $eleB = shift @listB;
		if (defined $eleB) {
			if (! $seen{$eleB}) {
				$seen{$eleB} = 1;
				push (@merged, $eleB);
			}
		}
	}

	return(@merged);
}
