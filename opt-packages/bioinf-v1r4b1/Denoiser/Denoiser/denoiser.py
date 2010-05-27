#!/usr/bin/env python 
from __future__ import division

""" A routine to clean up 454 sequencing data."""

__author__ = "Jens Reeder"
__copyright__ = "Copyright 2010, Jens Reeder, Rob Knight"
__credits__ = ["Jens Reeder", "Rob Knight"]
__license__ = "GPL"
__version__ = "0.84"
__maintainer__ = "Jens Reeder"
__email__ = "jens.reeder@gmail.com"
__status__ = "Pre-release"

from os import makedirs, remove
from os.path import exists
from optparse import OptionParser

from cogent.app.util import get_tmp_filename

from Denoiser.preprocess import STANDARD_BACTERIAL_PRIMER
from Denoiser.flowgram_clustering import greedy_clustering, secondary_clustering,\
     denoise_seqs
from Denoiser.utils import make_stats, store_mapping, store_clusters, create_dir

def parse_command_line_parameters(commandline_args=None):
    """ Parses command line arguments """

    version = 'Version: %prog '+__version__
    example_usage = """

Example:
Run denoiser on flowgrams in 454Reads.sff.txt with read-to-barcode mapping in seqs.fna,
put results into Outdir, log progress in Outdir/random_dir/denoiser.log :

%prog -i 454Reads.sff.txt -f seqs.fna -v -o Outdir
"""
    usage = 'usage: %prog [options] -i data.sff.txt' + example_usage
    parser = OptionParser(usage=usage, version=version)
 
    parser.add_option('-v','--verbose',action='store_true',\
                          dest='verbose', help='Print information during execution '+\
                          'into log file [default: %default]')

    parser.add_option('-i','--input_file',action='store',\
                          type='string',dest='sff_fp',help='path to flowgram file '+\
                          '[REQUIRED]')

    parser.add_option('-f','--fasta_fp',action='store',\
                          type='string',dest='fasta_fp',help='path to fasta input file '+\
                          '[default: %default]')

    parser.add_option('-o','--output_dir',action='store',\
                          type='string',dest='output_dir',help='path to output'+\
                          ' directory [default: %default]')

    parser.add_option('-c','--cluster',action='store_true',
                      dest='cluster',
                      help='Use cluster/multiple CPUs for '+\
                          'flowgram alignments [default: %default]')

    parser.add_option('-n','--num_cpus',action='store',
                      type='int',dest='num_cpus',
                      help='number of cpus, requires -c '+\
                          '[default: %default]')

#    parser.add_option('-q','--queue',action='store',\
#                          type='string', dest='queue', help='Specifiy queue for cluster '+\
#                          '[default: %default]')

    parser.add_option('-p','--preprocess_fp',action='store',\
                          type='string',dest='preprocess_fp',\
                          help='Do not do preprocessing (phase I), instead use already preprocessed ' +\
                          'data in PREPROCESS_FP')

    parser.add_option('-s','--squeeze',action='store_true',\
                          dest='squeeze', help='Use run-length encoding for prefix '+\
                          'filtering [default: %default]')
    parser.add_option('--force',action='store_true',\
                          dest='force', help='Force overwrite of existing '
                      +'directory [default: %default]')

    parser.add_option('-l','--log_file',action='store',\
                          type='string',dest='log_fp',help='path to log file '+\
                          '[default: %default]')

    parser.add_option('--primer',action='store',\
                          type='string',dest='primer',\
                          help='primer sequence '+\
                          '[default: %default]')

    parser.add_option('-b','--bail_out',action='store',
                      type='int',dest='bail',
                      help='stop clustering in phase II with '+
                      'clusters smaller than BAIL after first cluster phase '+
                      '[default: %default]')

    parser.add_option('--percent_id',action='store',\
                          type='float',dest='percent_id',
                      help='sequence similarity clustering '+\
                          'threshold [default: %default]')

    parser.add_option('--low_cut-off',action='store',\
                          type='float',dest='low_cutoff',
                      help='low clustering threshold for phase II '+\
                          '[default: %default]')

    parser.add_option('--high_cut-off',action='store',\
                          type='float',dest='high_cutoff',
                      help='high clustering threshold for phase III '+\
                          '[default: %default]')

    parser.add_option('--low_memory',action='store_true',\
                          dest='low_memory', help='Use slower, low '+\
                          'memory method [default: %default]')

    # Define defaults
    parser.set_defaults(verbose=False, cluster=False,
                        log_fp="denoiser.log", preprocess_fp=None,
                        primer=STANDARD_BACTERIAL_PRIMER,
                        sff_fp=None, input_fp=None, squeeze=False,
                        #queue="friendlyq",
                        num_cpus=2, output_dir=None, percent_id=0.97, bail=1,
                        low_cutoff=3.75, high_cutoff=4.5, force=False,
                        low_memory=False)
    
    opts,args = parser.parse_args(commandline_args)
    
    if (not opts.sff_fp or (opts.sff_fp and not exists(opts.sff_fp))):
        parser.error('Flowgram file path does not exist:\n %s \n Pass a valid one via -i.'
                     % opts.sff_fp)
    return opts,args


def main(commandline_args=None):
    from sys import argv
    opts, args = parse_command_line_parameters(commandline_args)
    verbose    = opts.verbose
    
    if opts.output_dir:
        #make sure it always ends on /
        tmpoutdir=opts.output_dir+"/"
    else:
        #make random dir in current dir
        tmpoutdir = get_tmp_filename(tmp_dir="", prefix="denoiser_", suffix="/")
    
    create_dir(tmpoutdir, not opts.force)
    
    denoise_seqs(opts.sff_fp, opts.fasta_fp, tmpoutdir, opts.preprocess_fp, opts.cluster,
                 opts.num_cpus, opts.squeeze, opts.percent_id, opts.bail, opts.primer,
                 opts.low_cutoff, opts.high_cutoff, opts.log_fp, opts.low_memory,
                 opts.verbose)
    
    # return outdir for tests/test_denoiser
    return tmpoutdir

if __name__ == "__main__":
    main()
