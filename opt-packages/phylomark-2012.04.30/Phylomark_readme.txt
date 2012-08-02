***Phylomark - a tool to find phylogenetic markers from whole genome alignments***
*contact: jasonsahl@gmail.com

#dependencies

-Biopython (www.biopython.org) #in .bashrc, point PYTHONPATH variable to Bio location
 (e.g. PYTHONPATH=/home/jsahl/biopython-1.53:$PYTHONPATH; export PYTHONPATH)
-bx-python-tools (https://bitbucket.org/james_taylor/bx-python/wiki/Home) #add to PYTHONPATH
 (e.g. PYTHONPATH=/home/jsahl/bx-python-central/lib:$PYTHONPATH; export PYTHONPATH)
-HashRF (http://code.google.com/p/hashrf/)

#the following scripts are included with Phylomark.  If you have an architecture different
than i86linux64, then you may need to re-compile on your system
-FastTree (http://www.microbesonline.org/fasttree/)
-mothur (http://www.mothur.org)
-muscle (http://www.drive5.com/muscle/)


Phylomark requires 5 files to run correctly:

1. concatenated alignment from the whole genome maf file
2. whole genome phylogeny
3. input mask from mothur showing polymorphic positions
4. combined multi-fastA of all genomes that went into the whole genome alignment
5. Reference genome from one isolate from the whole genome alignment

Files 1-4 can be created with the Phylomark_prey.py script included.  All you need to have is
the input MAF file, and a directory of genomes that went into the alignment.  Examples
of these files for E. coli are included on SourceForge

Phylomark_prep.py --input-maf=your.maf --fasta-dir=fasta_dir

#Now you want to alter the file, phylomark_env.sh, to set the Phylomark_DIR environment variable.
Then you can set the environment by:

source phylomark_env.sh

Once the files are generated and your environment is correct, Phylomark can be run by:

Phylomark.py -a <concatenated_alignment> -m <mothur_mask> -t <wga.tree> -r <reference_genome>
-c <combined_multi_fasta> 

Other parameters that can be changed include:
-s : step_size (integer).  The sliding window will move this many bases
-l : frag_length (integer).  Length of genomic fragments to include
-k : keep_length (integer).  Keep fragments if they contain this many polymorphisms
--parallel_workers= (integer) : number of processors to use

Known issues:

-if the genome name is too long, muscle will truncate it.  HashRF will then throw an error because
the names don't match compared to the whole genome phylogeny. 

***An additional script Phylomark_v1_1_R.py is included to provide more detailed analysis about
nucleotide frequencies in each genomic fragment

-Two new dependencies are required for this script:

R (tested version = 2.14.1)
bioStrings (http://www.bioconductor.org/packages/release/bioc/html/Biostrings.html)

-The snps.r script must be in the same directory as your other input files
(script is modified from http://manuals.bioinformatics.ucr.edu/home/ht-seq)

-A new directory is created (R_output).  For each fragment, two files are created.  One file
is a table showing the base frequencies at each position in the alignment.  The second file is
a .pdf showing a cluster dendrogram, and a plot showing the nucleotide conservation across
the length of the fragment.  As this directory can fill up rapidly, I recommend that you use
a larger step size (e.g. 10) and a larger fragment size (e.g. 800).  Then I would only look
at the plots and tables for my best performing fragments. 

