#!/bin/bash

TEMP=`getopt -o hV1:2:o:T:b:d:q:x:A:C: --long help,debug,ref: -n 'bmtagger' -- "$@"`

if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$TEMP"

accession=''
quality=0
reference=''
blastdb=''
srindex=''
bmfiles=''
input1=''
input2=''
output=/dev/stdout
done=0
debug=0

bmoptions="-TP -lN5 -z -L 1000000 -c 32 -s 4 --sra-read-clipinfo"
bmoptions_debug="-R --dump-as-fasta"
blastnopts="-outfmt 6 -word_size 16 -best_hit_overhang 0.1 -best_hit_score_edge 0.1 -use_index true"
srprismopts="-b 100000000 -n 1 -R 0 -r 1 -M 7168 --trace-level info"
	#-M 15360 

: ${TMPDIR:=/tmp}
: ${BMFILTER:=bmfilter}
: ${BLASTN:=blastn}
: ${SRPRISM:=srprism}
: ${EXTRACT_FA:=extract_fullseq}

function check_exec () {
	if [ "$1" == "" ] ; then return 0; fi
	if ! which "$1" >&2 ; then echo "FATAL: Failed to find $1" >&2 ; exit 20 ; fi
}

function show_help () {
	echo "usage: bmtagger [-hV] [-q 0|1] [-C config] -1 input.fa [-2 matepairs.fa] -b genome.wbm -d genome-seqdb -x srindex [-o blacklist] [-T tmpdir]"
	echo "usage: bmtagger [-hV] [-q 0|1] [-C config] -1 input.fa [-2 matepairs.fa] --ref=reference [-o blacklist] [-T tmpdir]"
	echo "usage: bmtagger [-hV] [-q 0|1] [-C config] -A accession [--ref=reference] [-b genome.wbm] [-d genome-seqdb] [-x srindex] [-T tmpdir]"
	echo "use --ref=name to point to .wbm, seqdb and srprism index if they have the same path and basename"
	echo "use --debug to leave temporary data on exit"
	done=1
}

function show_version () {
	echo "version 0.0.0"
	done=1
}

function finalize () {
	if [ $debug == 0 ] ; then rm -fr "$TMPDIR"/bmtagger.$tmpstr.* ; fi
	if [ "$1" == "" ] ; then exit 100 ; else exit "$1" ; fi
}

function parse_config () {
	local required="$1"
	local file="$2"
	if [ -e "$file" ] ; then
		echo "Config: Reading $file" >&2
		source $file
		rc="$?"
		if [ $rc != 0 ] ; then
			echo "Error: Failed to read file $file" >&2
			exit 22
		fi
	elif [ $required != 0 ] ; then
		echo "Error: failed to read $file" >&2
		exit 23
	else 
		echo "Info: no $file found" >&2
	fi
}

parse_config 0 ./bmtagger.conf

while true ; do
	case "$1" in
	-h|--help) show_help ; shift ;;
	-V) show_version ; shift ;;
	--debug) debug=1 ; shift ;;
	--ref) reference="$2" ; shift 2 ;;
	-1) input1="-1$2" ; shift 2 ;;
	-2) input2="-2$2" ; shift 2 ;;
	-o) output="$2" ; shift 2 ;;
	-A) if [ "$accession" == "" ] ; then accession="$2" ; else echo "ERROR: Can't use -A multiple times" >&2 ; exit 1 ; fi ; shift 2 ;;
	-C) parse_config 1 "$2" ; shift 2 ;;
	-b) bmfiles="$bmfiles -b$2" ; shift 2 ;;
	-d) blastdb="$2" ; shift 2 ;;
	-x) srindex="$2" ; shift 2 ;;
	-q) quality="$2" ;  shift 2 ;;
	-T) TMPDIR="$2" ; shift 2 ;;
	--) break ;;
	*) echo "Unknown option $1 $2" >&2 ; exit 1 ;;
	esac
done

echo "Using following programs:" >&2
check_exec "$BMFILTER"
check_exec "$SRPRISM"
check_exec "$BLASTN"
check_exec "$EXTRACT_FA"

if [ $done == 1 ] ; then exit 0 ; fi
if [ $debug != 0 ] ; then bmoptions="$bmoptions $bmoptions_debug" ; BMFILTER="time $BMFILTER" ; SRPRISM="time $SRPRISM" ; fi

if [ ! -d "$TMPDIR" ] ; then
	echo "FATAL: $TMPDIR is not directory" >&2 
	exit 21 
fi

spotId_only=""

if [ "$accession" != "" ] ; then
	if [ "$input1:$input2" != ":" ] ; then
		echo "ERROR: One should not use -A with -1, -2" >&2 
		exit 1 
	fi
	if [ "$output" == "/dev/stdout" ] ; then output=. ; fi
	test -d "$output" || mkdir -p "$output"
	test -d "$output" || { echo "ERROR: failed to create directory [$output]" >&2 ;  exit 100 ; }
	output="$output/$accession.blacklist"
	accession="-A$accession"
	spotId_only="-I"
fi

case "$output" in
	-) output="/dev/stdout" ; tmpout="$output" ;;
	/dev/*) tmpout="$output" ;;
	*) tmpout="$output~" ;;
esac

test -z "$srindex" && srindex="$reference"
test -z "$blastdb" && blastdb="$reference"
test -z "$bmfile"  && bmfile="$reference".wbm

echo "RUNNING $0 (PID=$$)" >&2
trap finalize INT TERM USR1 USR2 HUP

tmpstr=`date '+%s'`.`hostname -s`.$$

$BMFILTER $accession $input1 $input2 -q $quality $bmfiles $spotId_only -o "$TMPDIR"/bmtagger.$tmpstr $bmoptions
rc=$?

if [ $rc != 0 ] ; then
	echo "FAILED: bmfilter with rc=$rc" >&2 ; 
	finalize 2
fi

function align_long () {
	test -s "$1".fa || return 0
	echo "RUNNING align_long for '$1'" >&2
	$BLASTN \
		-task megablast \
		-db "$blastdb" \
		-query "$1".fa \
		-out   "$1".bn \
		-index_name "$blastdb" \
		$blastnopts
	rc=$?
	if [ $rc != 0 ] ; then echo "FAILED: blastn for $1" >&2 ; finalize 3 ; fi
	## blastn filter criteria: $4 = hitLength, $3 = %id, $1 = readID
	awk '($4 >= 90 || ($4 >= 50 && $3 >= 90)) { print $1 }' "$1".bn > "$1".lst
	rc=$?
	if [ $rc != 0 ] ; then echo "FAILED: awk for blastn results for $1" >&2 ; finalize 4 ; fi
	return $rc
}

function align_short () {
	test -s "$1".fa || return 0
	echo "RUNNING align_short for '$1'" >&2
	$SRPRISM search \
		-I "$srindex" \
		-i "$1".fa \
		-o "$1".srprism \
		-T "$TMPDIR" \
		-O tabular \
		$srprismopts
	rc=$?
	if [ $rc != 0 ] ; then echo "FAILED: srprism for $1" >&2 ; finalize 5 ; fi
	## srprism filter criteria: everything, $2 = readID
	awk '{ print $2 }' "$1".srprism > "$1".lst
	rc=$?
	if [ $rc != 0 ] ; then echo "FAILED: awk for srprism results for $1" >&2 ; finalize 6 ; fi
	return $rc
}

function append () {
	test -s "$2" || return 0
	uniq "$2" >> "$1"
	rc=$?
	if [ $rc != 0 ] ; then echo "FAILED: cat $2 >> $1 with rc=$?" >&2 ; finalize 7 ; fi
	return $rc
}

function extract_fa () {
	test -z "$EXTRACT_FA" && return 0
	test -s "$1".lst || return 0
	test -s "$1"2.fa || return 0
	"$EXTRACT_FA" "$1".lst "$1"2.fa -remove -fasta > "$1"2x.fa
	rc=$?
	if [ $rc != 0 ] ; then echo "FAILED: $EXTRACT_FA with rc=$?" >&2 ; finalize 8 ; fi
	return $rc
}

align_short "$TMPDIR"/bmtagger.$tmpstr.short
extract_fa  "$TMPDIR"/bmtagger.$tmpstr.short
align_short "$TMPDIR"/bmtagger.$tmpstr.short2x

align_long "$TMPDIR"/bmtagger.$tmpstr.long
extract_fa "$TMPDIR"/bmtagger.$tmpstr.long
align_long "$TMPDIR"/bmtagger.$tmpstr.long2x

awk '($2 == "H") { print $1 }' "$TMPDIR"/bmtagger.$tmpstr.tag >> "$tmpout"
rc=$?
if [ $rc != 0 ] ; then echo "FAILED: awk for tagfile" >&2 ; finalize 8; fi

append "$tmpout" "$TMPDIR"/bmtagger.$tmpstr.short.lst
append "$tmpout" "$TMPDIR"/bmtagger.$tmpstr.short2x.lst
append "$tmpout" "$TMPDIR"/bmtagger.$tmpstr.long.lst
append "$tmpout" "$TMPDIR"/bmtagger.$tmpstr.long2x.lst

if test "$tmpout" != "$output" ; then
	mv "$tmpout" "$output"
	rc=$?
	if [ $rc != 0 ] ; then 
		echo "FAILED to move [$tmpout] to [$output]" >&2 
		finalize 9
	fi
fi

echo "DONE $0 (PID=$$)" >&2
finalize 0

