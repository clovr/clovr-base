
                   BMtool: word Bitmap Manipulation tool

                                NCBI/NLM/NIH

                                23 July 2010

                               Version 3.101

   Generate bitmap file representing words present in genome to be used
   in bmfilter and bmtagger.sh.

  Table of Contents

     * [1]Synopsis 
     * [2]Description 
     * [3]Options 
          + [4]General options 
          + [5]File options 
          + [6]Word parameters 
          + [7]Output parameters 
          + [8]Other options 
     * [9]Compression 
     * [10]Return codes 

Synopsis

   Get help and version:
   bmtool -hV

   Generate bitmap from reference blastdb or fasta file:
   bmtool -d reference [-l gilist] -o output.bitmap -w wordSize

   Generate compressed bitmap from reference blastdb or fasta file:
   bmtool -d reference [-l gilist] -o output.bitmap -w wordSize -v 2 -z

   Convert bitmap file to the compressed version:
   bmtool -i input.bitmap -o output.bitmap -w wordSize -v2 -z

Description

   bmtool is a tool to generate and manipulate bitmap files which can be
   used by bmfilter and bmtagger.sh. Bitmap file stores information which
   k-mers of all possible ones are present in reference sequence set.

   bmtool can generate bitmap file from reference fasta file, from
   reference seqdb (in this case list of gis to limit to may be provided)
   or from existing bitmap file (which is useful for
   compressing/decompressing existing file).

Options

    General options

   --help
   -h
          Print help and effective values of arguments and exit with
          error code 0
   --version
   -V
          Print version end exit with error code 0

    File options

   --fasta-file=filename
   -d filename
          Input fasta or blastdb file (should not be used with -i)
   --output-file=filename
   -o filename
          Output word bitmask file
   --gi-list=filename
   -l filename
          Set gi list for blastdb file (may be used with -d blastdb)
   --input-file=filename
   -i filename
          Set word bitmask file as input (should not be used with -d)
   --fasta-parse-ids=true|false
          Parse FASTA ids (result becomes broken if ranges are used as
          part of seq-ids)

    Word parameters

   --word-size=value
   -w value
          Word size to use for hashing; is ignored if -p pattern is used
   --word-step=value
   -S value
          Step (stride size) to use; 1 is default
   --max-amb=value
   -A value
          Maximal number of ambiguities to use (if 0 then any words which
          include ambiguities will be ignored, if greater then 0 then
          words with up to that many ambiguity characters will be used to
          mark positions as set in output bitmap)
   --pattern=value
   -p value
          Set pattern (integer bitmask value with 0 bit meaning that the
          base will be skipped from word generation) to use with
          discontiguous words, 0x or 0b prefix may be used for hex or bin
          (-w## will be ignored)

    Output parameters

   --version=0|1|2
   -v 0|1|2
          Output file format version. Only version 2 supports
          compression, versions 1,2 support patterns.
   --compress
   -z
          Create compressed version of file (requires file format version
          2 to be specified)
   --extra-compress
   -Z
          Compress bitmask (requires file format version 2) looking for
          duplicate extension sets; may be noticeably slower but may give
          somewhat better compression
   --pack-prefix-bits=value
          How many bits to use for compression prefix
   --pack-offset-bits=value
          Number of bits in table to use for data segment offset
   --pack-count-bits=value
          Number of bits to reserve for entry count within segment

   Options --pack-*-bits have defaults that seem to make best compression
   for Human genome (build 37) with word size of 18. See section
   "compression" for explanation.

    Other options

   Most of following options are useful only for testing program and only
   when converting one bitmap to another.
   --mmap
          Memory map source bitmap file instead of reading; may be
          helpful to decrease memory footprint
   --diff
          Diff source and result before writing result, repport
          differences; useful to test correctness
   --slow
          Slow copy (using query API -- to check query api correctness)
   --bit-test
          Test core bit operations -- to check program code correctness

Compression

   For compression, each word present in reference is split into prefix
   and suffix parts by --pack-prefix-bits option which sets number of
   bits in prefix (respectively, number of bits in suffix is determined
   as double of number of bases in word minus number of bits in prefix).

   Prefix is used as index in compression table which has two columns:
   number of words with this prefix (size of this column is set with
   --pack-count-bits) and offset of corresponding data segment in file
   (size of this column is controlled by --pack-offset-bits). Data
   segments contain either bitmap for all words sharing the same prefix,
   or list of all suffixes sharing the same prefix -- whichever takes
   less space.

Return codes

   On error bmtool returns non-zero code, on success it returns 0.

