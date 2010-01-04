#!/bin/bash

######################################################################
##
## This script will run the BER pipeline.  If the database(s) are
## formatted with xdformat (http://blast.wustl.edu/), xdget must be
## in $PATH.  If the database(s) are formatted with
## cdbfasta (http://www.tigr.org/tdb/tgi/software/cdbfasta_usage.html),
## cdbyank must be in $PATH.  If the database(s) are formatted with
## formatdb (http://www.ncbi.nlm.nih.gov/BLAST/), fastacmd must be in
## $PATH.
##
##
## Please contact Ed Lee (elee@tigr.org) in case of any questions or
## bug reports.
######################################################################

## variables
bin_dir=`cd $(dirname $0) && pwd`/bin
tmp_dir=./tmp
out_dir=./out

db_format=xdformat
nuc_db_format=xdformat

## usage information
print_usage()
{
	progname=`basename $0`
	cat << END
usage: $progname -i|--blast_hits <input_blast_hits>
	-d|--db <protein_database_blasted_against>
	[-f|--db_format <protein_database_format>]
	[
		-D|--nuc_db <nucleotide_database_for_query_proteins>
		[-F|--nuc_db_format <nucleotide_database_format>]
		-m|--prot_nuc_map <protein_nucleotide_id_map>
	] |
	[	-I|--nuc_fasta <nucleotide_fasta>
	]
	[-B|--bin_dir <binary_directory_location>]
	[-T|--tmp_dir <temporary_directory>]
	[-O|--out_dir <output_directory>]
	[-b|--min_bit_score <min_bitscore_for_processing_hit>]
	[-r|--min_raw_score <min_rawscore_for_processing_hit>]
	[-p|--min_pct_id <min_percent_identity_for_processing_hit>]
	[-P|--min_pct_sim <min_percent_similarity_for_processing_hit>]
	[-e|--max_evalue <max_e_value_for_processing_hit>]
	[-E|--max_pvalue <max_p_value_for_processing_hit>]
	[-n|--max_num_hits <max_number_of_hits_per_query>]
	[-N|--max_num_hits_per_region <max_number_of_hits_per_unique_region>]

	i: input BLAST hits (in the native output format)
	d: protein database BLASTed against
	f: format of protein database [xdformat (default) | cdbfasta |
				       formatdb]
	   (if going against NIAA, it might be in cdbfasta format)
	D: nucleotide database containing nucleotide counterparts to
	   query proteins
	F: format of nucleotide database [xdformat (default) | cdbfasta |
					  formatdb]
	m: tab delimited map for protein identifiers to
	   nucleotide identifiers
	I: nucleotide FastA (should contain only one sequence, corresponding
	   to the query protein - implies only one query protein in hit
	   file - useful for parallization)
	B: location of BER binaries [default = \$install_dir/bin]
	T: location of temporary directory [default = \$current_dir/tmp]
	O: location of output directory [default = \$current_dir/out]
	b: mininum bitscore for processing hit
	r: minimum rawscore for processing hit
	p: minimum percent identity for processing hit
	P: minimum percent similarity for processing hit
	e: maximum e_value for processing hit
	E: maximum p_value for processing hit
	n: maximum number of hits per query
	N: maximum number of hits per unique region
END
	exit 1
}

## init environment
init_vars()
{
	export PATH=$bin_dir:$PATH
}

run_command()
{
	echo $* > /dev/stderr
	/bin/bash -c "$*" 2> /dev/null
	ec=$?
	if [ $ec -ne 0 ]
	then
		echo "Error running $1" > /dev/stderr
		exit $ec
	fi
}

function check_opt()
{
	if [ -z $1 ]
	then
		echo $2 > /dev/stderr
		print_usage
	fi
}

parse_options()
{
	set -- `getopt -u -n $(basename $0) -o B:T:O:i:b:r:p:P:e:E:n:N:d:f:D:F:m:I:h -l bin_dir:,tmp_dir:,out_dir:,blast_hits:,min_bit_score:,min_raw_score:,min_pct_id:,min_pct_sim:,min_evalue:,min_pvalue:,max_num_hits:,max_num_hits_per_region:,db:,db_format:,nuc_db:,nuc_db_format:,prot_nuc_map:,nuc_fasta:,help -- "$@"; echo $?`
	test ${!#} -ne 0 && print_usage
	for opt
	do
		case $opt in
			-B|--bin_dir)
				bin_dir=$2; shift 2;;
			-T|--tmp_dir)
				tmp_dir=$2; shift 2;;
			-O|--out_dir)
				out_dir=$2; shift 2;;
			-i|--blast_hits)
				blast_hits=$2; shift 2;;
			-b|--min_bit_score)
				min_bit_score=$2; shift 2;;
			-r|--min_raw_score)
				min_raw_score=$2; shift 2;;
			-p|--min_pct_id)
				min_pct_id=$2; shift 2;;
			-P|--min_pct_sim)
				min_pct_sim=$2; shift 2;;
			-e|--max_evalue)
				max_evalue=$2; shift 2;;
			-E|--max_pvalue)
				max_pvalue=$2; shift 2;;
			-n|--max_num_hits)
				max_num_hits=$2; shift 2;;
			-N|--max_num_hits_per_region)
				max_num_hits_per_region=$2; shift 2;;
			-d|--db)
				db=$2; shift 2;;
			-f|--db_format)
				db_format=$2; shift 2;;
			-D|--nuc_db)
				nuc_db=$2; shift 2;;
			-F|--nuc_db_format)
				nuc_db_format=$2; shift 2;;
			-m|--prot_nuc_map)
				prot_nuc_map=$2; shift 2;;
			-I|--nuc_fasta)
				nuc_fasta=$2; shift 2;;
			-h|--help)
				print_usage;;
			--)
				shift; break;;
		esac
	done
	check_opt "$blast_hits" "No blast hits provided"
	check_opt "$db" "No protein database provided"
	if [ -z $nuc_fasta ]
	then
		check_opt "$nuc_db" "No nucleotide database provided"
		check_opt "$prot_nuc_map" "No protein-nucleotide map provided"
	fi
}

append_opts()
{
	test $2 && cmd=${cmd}" $1 $2"
}

make_dir()
{
	run_command rm -rf $1
	run_command mkdir -m 755 -p $1
}

parse_options "$@"
init_vars

## create directories
make_dir $tmp_dir
make_dir $out_dir

## convert blast output to tabbed format
run_command wu-blast2btab -i $blast_hits -o $tmp_dir/hits.btab

## group hits by query id
run_command group_blast_hits -i $tmp_dir/hits.btab -d $tmp_dir -q

## filter blast hits
for i in $tmp_dir/*/*hits.btab.*
do
	cmd="ber_blast_hit_selector -i $i -o $(echo $i | sed -e 's/hits.btab/hits.filtered.btab/g')"
	append_opts -b $min_bit_score;
	append_opts -r $min_raw_score;
	append_opts -p $min_pct_id;
	append_opts -P $min_pct_sim;
	append_opts -e $max_evalue;
	append_opts -E $max_pvalue;
	append_opts -n $max_num_hits;
	append_opts -N $max_num_hits_per_region;
	run_command $cmd
done

## create mini db
for i in $tmp_dir/*/*hits.filtered.btab.*
do
	cmd="fetch_fasta_from_db -I <(cut -f6 $i | sort | uniq) -d $db -p T -f $db_format -o $(echo $i | sed -e 's/hits.filtered.btab/minidb.fsa/g')"
	run_command $cmd
done

## create nuc db
for i in $tmp_dir/*/*hits.filtered.btab.*
do
	if [ -z $nuc_fasta ]
	then
		cmd="fetch_fasta_from_db -I <(grep $(cut -f1 $i | head -1) $prot_nuc_map | cut -f2) -d $nuc_db -p F -f $nuc_db_format -o $(echo $i | sed -e 's/hits.filtered.btab/nucdb.fsa/g')"
	else
		cmd="cp $nuc_fasta $(echo $i | sed -e 's/hits.filtered.btab/nucdb.fsa/g')"
	fi
	run_command $cmd
done

## praze
for i in $tmp_dir/*/minidb.fsa.*
do
	cmd=`cat << END
praze -O $(echo $i | sed -e 's/minidb.fsa/praze/g' | sed -e "s%$tmp_dir/.*/%%g") -o $(echo $i | sed -e 's/minidb.fsa.*$//g') \$(echo $i | sed -e 's/minidb/nucdb/g') $i
END`
	run_command $cmd
done

## create output files
run_command "cat $tmp_dir/*/praze.*.nr > $out_dir/praze.out"
run_command "cat $tmp_dir/*/praze.*.nr.btab > $out_dir/praze.out.btab"

