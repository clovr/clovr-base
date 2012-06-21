
   BMTagger: Best Match Tagger for removing human reads from metagenomics
                                  datasets

                                NCBI/NLM/NIH

                               07 March 2011

                               Version 3.101

   Given FASTA, FASTQ files or SRA accession of microbiome dataset,
   produce list of reads that are most probably human contaminants and
   should not be disclosed to public

  Table of Contents

     * [1]Quick start 
          + [2]Steps done once per reference genome 
          + [3]Commands for running the tagger 
     * [4]Synopsis 
     * [5]Options 
     * [6]Environment 
     * [7]Config files 
     * [8]Return codes 

Quick start

   This script requires programs bmfilter, srprism, extract_fullseq and
   blastn to be available in the path. It also needs bmtool to prepare
   bitmask file for the reference genome. Help for these programs is
   available by typing the program name followed by ``-h''.

   Programs run from this script (bmfilter, srprism) require about 8.5Gb
   memory and three times as much harddisk space for index data. Disk
   space needed for temporary files depends on input, and is typically
   the same size as that of the input for metagenomic datasets.

    Steps done once per reference genome

   The steps are:
    1. Make index for bmfilter using command
         bmtool -d <reference.fa> -o <reference.bitmask> -A 0 -w 18
       where reference.fa is a fasta file for the screening database. For
       HMP, this can be the human genome. Output is a binary file
       generated in reference.bitmask
    2. Make index for srprism
         srprism mkindex -i <reference.fa> -o <reference.srprism> -M 7168
       This generates files with prefix reference.srprism
    3. Make blastdb for blast
         makeblastdb -in <reference.fa> -dbtype nucl
       This generates database files for blastn. makeblastdb and blastn
       can be downloaded from blast distribution:
       ftp://ftp.ncbi.nlm.nih.gov/blast/executables/release/LATEST/

    Commands for running the tagger

   The commands depend on the data source for reads.
   For single reads in fasta format, the command is:
          bmtagger.sh -b reference.bitmask -x reference.srprism \
            -T tmp -q0 -1<file.fa> -o<file.out>
   For paired reads in fasta format, the command is:
          bmtagger.sh -b reference.bitmask -x reference.srprism \
            -T tmp -q0 -1<mate1.fa> -2<mate2.fa> -o<file.out>
   For single reads in fastq format, the command is:
          bmtagger.sh -b reference.bitmask -x reference.srprism \
            -T tmp -q1 -1<file.fq> -o<file.out>
   For paired reads in fastq format, the command is:
          bmtagger.sh -b reference.bitmask -x reference.srprism \
            -T tmp -q1 -1<mate1.fq> -2<mate2.fq> -o<file.out>
   For reads read directly from SRA, the command is:
          bmtagger.sh -b reference.bitmask -x reference.srprism \
            -T tmp -A <run> -o <outdir>

   In all above scenarios, -b, -x, and -T specify the index for bmfilter,
   the index for srprism, and the directory to use for temporary files,
   respecitvely. If no temporary directory is specified, current working
   directory is used. Flag -q of 0 and 1 specify fasta and fastq input
   files, respectively. Output specified by -o is a file name if input is
   fasta or fastq, and it is a directory if the input is a run. The
   output for, say run SRR059480, when -o is myresults will be a file
   myresults/SRR059480.blacklist that contains the SRA indexes of reads
   found to be human rather than the full id. Output files with inputs as
   fasta or fastq contain the ids of reads found to be human.

Synopsis

   bmtagger.sh [-hV] [-C config] query-options database-options \
     [-o blacklist] [-T tmpdir] [--debug]

   where [query-options] are either:
     -q0 -1 input.fa [-2 matepairs.fa]
   or:
     -q1 -1 input.fq [-2 matepairs.fq]
   or:
     -A accession

   and [database-options] are:
     -b reference.bitmask -x reference.srprism [-d reference.seqdb]

Options

   -h
          Prints help to stdout and exits with error code 0
   -V
          Prints version to stdout and exits with error code 0
   -C config
          Reads config file, overriding previously set values. Subsequent
          options may override values set in current config file.
   -q quality
          Number of quality channels on input (0|1). Should be 0 with
          FASTA and 1 with FASTQ input files.
   -1 reads
          Specifies input file name -- should be FASTA if -q is 0 or
          FASTQ if -q is 1.
   -2 mates
          Specifies input file name for read mates, required to be in the
          same format as the file specified with -1 option, and should
          have all same read IDs and in the same order. Requires option
          -1.
   -A run-accession
          Specifies SRA run accession. Requires bmfilter to be compiled
          with SRA toolkit and data to be organized as required by SRA
          specifications. Should not be used with option -1.
   -b reference.bitmask
          Specifies filename of the reference genome bitmask, proviously
          generated by bmtool
   -x reference.srprism
          Specifies base of the filename for the previously generated
          srprism index.
   -d reference.seqdb
          Specifies path to blastdb generated by formatdb. Is not used
          unless options passed to bmfilter are modified to generate data
          for blastn (see details below).
   --ref=reference
          Specifies basename for reference indices, literally
          --ref=abc/def means "-b abc/def.wbm -x abc/def.srprism
          -d abc/def".
   -T tmpdir
          Specifies directory to be used for temporary files (default is
          to use value of $TMPDIR)
   -o output
          If -1 is used this option provides script with the name for
          output file which will contain list of IDs to be tagged as
          matching reference genome. Otherwise if -A is used, "output" is
          considered to be name of directory, where output file(s) named
          by SRA run accession(s) with suffix .blacklist will be created
          by the script.
   --debug
          Will prevent script from deleting temporary files. Also run
          times for srprism and bmfilter will be reported.

Environment

   PATH
          is used to find programs called from script
   TMPDIR
          if set is used to initialize temporary directory, otherwise
          /tmp is used
   SRPRISM
          if set specifies name and optianally path to srprism
   BMFILTER
          if set specifies name and optionally path to bmfilter
   EXTRACT_FA
          if set specifies name and optionally path to extract_fullseq
   BLASTN
          if set specifies name and optionally path to blastn

Config files

   At start time bmtagger.sh looks for file bmtagger.conf and if it is
   present imports it. Also every time option -C is used, bmtagger.sh
   tries to parse it, and ends with error if file is not found.

   Config file is regular shell script which may set any variables
   specified in "Environment" section, plus any of following:

   bmfiles
          if set specifies bmfilter bitmap file
   blastdb
          if set specifies blastdb for blastn
   srindex
          if set specifies srprism index file

Return codes

   On error bmtagger.sh returns non-zero code, on success it returns 0.
   In any case, if --debug is not specified, bmtagger.sh deletes all
   temporary files.

