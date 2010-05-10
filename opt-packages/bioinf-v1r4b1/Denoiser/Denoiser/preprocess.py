#!/usr/bin/env python 

"""Preprocess 454 sequencing data."""

__author__ = "Jens Reeder"
__copyright__ = "Copyright 2010, Jens Reeder, Rob Knight"
__credits__ = ["Jens Reeder", "Rob Knight"]
__license__ = "GPL"
__version__ = "0.84"
__maintainer__ = "Jens Reeder"
__email__ = "jens.reeder@gmail.com"
__status__ = "Pre-release"

from optparse import OptionParser
from itertools import imap
from os.path import exists
from os import remove, rename, rmdir, makedirs
from random import sample
from collections import defaultdict
from string import lowercase

from cogent.util.trie import build_prefix_map
from cogent.parse.fasta import MinimalFastaParser
from cogent.app.util import get_tmp_filename
from cogent.parse.flowgram import Flowgram, build_averaged_flowgram
from cogent.parse.flowgram_parser import lazy_parse_sff_handle

from Denoiser.cluster_utils import submit_jobs
from Denoiser.Flowgram_filter import cleanup_sff, writeSFFHeader, split_sff,\
     truncate_flowgrams_in_SFF, extract_barcodes_from_mapping
from Denoiser.utils import squeeze_seq, make_stats, get_representatives, \
     waitForFile, store_mapping, invert_mapping
from Denoiser.settings import PYTHON_BIN, PROJECT_HOME

STANDARD_BACTERIAL_PRIMER = "CATGCTGCCTCCCGTAGGAGT"

def makeTmpName(length = 8):
    """Returns a random string of specified length.
    
    length: length of random string
    """
    return ("".join(sample(list(lowercase), length)))

def parse_command_line_parameters(commandline_args=None):
    """ Parses command line arguments """
    usage = 'usage: %prog [options]'
    version = 'Version: %prog '+ __version__
    parser = OptionParser(usage=usage, version=version)

    # A binary 'verbose' flag
    parser.add_option('-v','--verbose',action='store_true',\
                          dest='verbose', help='Print information during execution -- '+\
                          'useful for debugging [default: %default]')

    parser.add_option('-i','--input_file',action='store',\
                          type='string',dest='sff_fp',help='path to flowgram file '+\
                          '[REQUIRED]')

    parser.add_option('-f','--fasta_file',action='store',\
                          type='string',dest='fasta_fp',help='path to fasta input file '+\
                          '[default: %default]')

    parser.add_option('-s','--squeeze',action='store_true',\
                          dest='squeeze', help='Use run-length encoding for prefix '+\
                          'filtering [default: %default]')

    parser.add_option('-l','--log_file',action='store',\
                          type='string',dest='log_fp',help='path to log file '+\
                          '[default: %default]')
 
    parser.add_option('-p','--primer',action='store',\
                          type='string',dest='primer',help='primer sequence'+\
                          '[default: %default]')

    parser.add_option('-o','--output_dir',action='store',\
                          type='string',dest='output_dir',help='path to output directory '+\
                          '[default: %default]')
    
    # Define defaults
    parser.set_defaults(verbose=False, log_fp="preprocess.log",
                        primer=STANDARD_BACTERIAL_PRIMER,
                        sff_fp=None, input_fp=None, squeeze=False, output_dir="/tmp/")
    
    opts,args = parser.parse_args(commandline_args)
    
    if (not opts.sff_fp or (opts.sff_fp and not exists(opts.sff_fp))):
        parser.error('Flowgram file path does not exist:\n %s \n Pass a valid one via -s.'
                     % opts.sff_fp)
    return opts,args


def sample_mapped_keys(mapping, min_coverage=50):
    """sample up to min_coverage keys for each key in mapping.

    mapping: dictionary of lists.
    
    Note: key is always included in sample
    """
    if min_coverage==0:
        return {}
    sample_keys = {}
    for key in mapping.keys():
        if (min_coverage>1):
            sample_keys[key] = sample(mapping[key],
                                      min(min_coverage-1, len(mapping[key])))
        else:
            sample_keys[key] = []
        sample_keys[key].append(key) #always include the centroid
    return sample_keys

def build_averaged_flowgrams(mapping, sff_fp,
                             min_coverage=50, out_fp=None):
    """Build averaged flowgrams for each cluster in mapping.
    
    mapping: a cluster mapping as dictionary of lists
    
    sff_fp: pointer to sff.txt file, must be consistent with  mapping
    
    min_coverage: number of flowgrams to average over for each cluster

    out_fp: ouput file name

    NOTE: This function has no test code, since it is mostly IO around tested functions
    """

    l = len(mapping)
    (flowgrams, header) = lazy_parse_sff_handle(open(sff_fp))
    #update some values in the sff header
    header["# of Reads"] = l
    header["Index Length"] = "NA"

    if (out_fp):
        out_filename=out_fp
    else:
        out_filename = get_tmp_filename(tmp_dir="/tmp/",
                                        prefix="prefix_dereplicated_averaged",
                                        suffix = ".sff.txt")
    outhandle = open(out_filename, "w")
    
    #write out reduced flogram set
    writeSFFHeader(header, outhandle)

    seqs = {}
    # get a random sample for each cluster
    sample_keys = sample_mapped_keys(mapping, min_coverage)
    for ave_f,id in _average_flowgrams(mapping, flowgrams, sample_keys):
        outhandle.write(ave_f.createFlowHeader()+"\n")
        ave_f.Bases = ave_f.toSeq()        
        seqs[id] = ave_f.Bases
    
    outhandle.close()
    return(out_filename, seqs)

def _average_flowgrams(mapping, flowgrams, sample_keys):
    """average flowgrams according to cluster mapping.

    mapping: a dictionary of lists as cluster mapping

    flowgrams:  an iterable flowgram source, all flowgram ids from this source must be in the mapping

    sample_keys: the keys that should be averaged over for each cluster.
    """

    flows = defaultdict(list) # accumulates flowgram for each key until sample for this key is empty
    invert_map = invert_mapping(mapping)
    for f in flowgrams:
        key = invert_map[f.Name]
        samples = sample_keys[key]
        if (f.Name in samples):
            flows[key].append(f.flowgram)
            samples.remove(f.Name)
            if (len(samples)==0):
                #we gathered all sampled flowgrams for this cluster,
                #now average
                ave_flowgram = build_averaged_flowgram(flows[key])
                ave_f = Flowgram(ave_flowgram, Name=key)
               
                del(flows[key])
                yield ave_f, key
                
def prefix_filter_flowgrams(flowgrams, squeeze=False):
    """Filters flowgrams by common prefixes.

    flowgrams: iterable source of flowgrams
    
    squeeze: if True, collapse all poly-X to X

    Returns prefix mapping.
    """

    #collect flowgram sequences
    if squeeze:
        seqs = imap(lambda f: (f.Name, squeeze_seq(str(f.toSeq(truncate=True)))),
                    flowgrams)
    else:
        seqs = imap(lambda f: (f.Name, str(f.toSeq(truncate=True))), flowgrams)
    #equivalent but more efficient than 
    #seqs = [(f.Name, str(f.toSeq(truncate=True))) for f in flowgrams] 
 
    #get prefix mappings
    mapping = build_prefix_map(seqs)
    l = len(mapping)
    orig_l=sum([len(a) for a in mapping.values()]) +l;

    return (l, orig_l, mapping)

def print_rep_seqs(mapping, seqs, out_fp):
    """Print the cluster seeds of a mapping to out_fp."""
    out_fh = open(out_fp+"/prefix_dereplicated.fasta","w")
    for s in (get_representatives(mapping, seqs.iteritems())):
        out_fh.write(s.toFasta()+"\n")
    out_fh.close()

def preprocess(sff_fp, log_fh, fasta_fp=None, out_fp="/tmp/",
               verbose=False, squeeze=False, 
               primer=STANDARD_BACTERIAL_PRIMER):
    """Quality filtering and truncation of flowgrams."""

    if(fasta_fp):
        #remove barcodes and sequences tossed by split_libraries, i.e. not in fasta_fp
        labels = imap(lambda (a,b): a, MinimalFastaParser(open(fasta_fp)))
        barcode_mapping = extract_barcodes_from_mapping(labels)
        (trunc_sff_fp, l) = truncate_flowgrams_in_SFF(open(sff_fp),
                                                      outdir=out_fp,
                                                      barcode_mapping=barcode_mapping,
                                                      primer=primer)
        if verbose:
            log_fh.write("Sequences in barcode mapping: %d\n" % len(barcode_mapping))
            log_fh.write("Truncated flowgrams written: %d\n" % l)
    else:                                 
        #just do a simple clean and truncate
        (clean_sff_fp, l) = cleanup_sff(open(sff_fp), outdir=out_fp)
        if verbose:
            log_fh.write("Cleaned flowgrams written: %d\n" % l)
        (trunc_sff_fp, l) = truncate_flowgrams_in_SFF(open(clean_sff_fp),
                                                      outdir=out_fp, primer=primer)
        if verbose:
            log_fh.write("Truncated flowgrams written: %d\n" % l)
        remove(clean_sff_fp)
        
    # Phase I - cluster seqs which are exact prefixe
    if verbose:
        log_fh.write("Filter flowgrams by prefix matching\n")
     
    (flowgrams, header) = lazy_parse_sff_handle(open(trunc_sff_fp))
    l, orig_l, mapping =\
        prefix_filter_flowgrams(flowgrams, squeeze=squeeze)
 
    averaged_sff_fp, seqs = build_averaged_flowgrams(mapping, trunc_sff_fp,
                                                     min_coverage=1,  #averaging produces too good flowgrams
                                                     #such that the greedy clustering clusters too much.
                                                     #Use the cluster centroid instead
                                                     out_fp=out_fp+"/prefix_dereplicated_averaged.sff.txt")
    remove(trunc_sff_fp)
    if verbose:    
        log_fh.write("Prefix matching: removed %d out of %d seqs\n"
                     % (orig_l-l, orig_l))
        log_fh.write("Remaining number of sequences: %d\n" % l)
        log_fh.write(make_stats(mapping)+"\n")
 
    #print representative sequences and mapping
    print_rep_seqs(mapping, seqs, out_fp)
    store_mapping(mapping, out_fp, "prefix")
    return (averaged_sff_fp, l, mapping, seqs)

def preprocess_on_cluster(sff_fp, log_fp, fasta_fp=None, out_fp="/tmp/",
                          squeeze=False, verbose=False,
                          primer=STANDARD_BACTERIAL_PRIMER):
    """Call preprocess via cluster_jobs_script on the cluster."""

    cmd = "%s %s/Denoiser/preprocess.py -i %s -l %s -o %s" % (PYTHON_BIN,
                                      PROJECT_HOME, sff_fp, log_fp, out_fp)
    if (fasta_fp):
        cmd += " -f %s" % fasta_fp
    if(squeeze):
        cmd += " -s"
    if verbose:
        cmd += " -v"
    if primer:
        cmd += " -p %s" % primer

    submit_jobs([cmd], "pp_"+makeTmpName(6))

    waitForFile(out_fp+"/prefix_mapping.txt", 10)

def read_preprocessed_data(out_fp="/tmp/"):
    """Read data of a previous preprocessing run."""

    # read mapping, and extract seqs
    # mapping has fasta_header like this:
    #  > id:   count

    seqs = dict([(a.split(':')[0],b) for (a,b) in
                (MinimalFastaParser(open(out_fp+"/prefix_dereplicated.fasta")))])
    mapping = {}
    for cluster in open(out_fp+"/prefix_mapping.txt"):
        cluster, members = cluster.split(':')
        mapping[cluster] = members.split()

    return(out_fp+"/prefix_dereplicated_averaged.sff.txt", len(mapping), mapping, seqs)

def main(commandline_args=None):
    from sys import argv
    opts, args = parse_command_line_parameters(commandline_args)

    #make tmp and output dir
    tmp_dir = get_tmp_filename(tmp_dir = opts.output_dir+"/", suffix="/")
    try:
        makedirs(tmp_dir)
    except OSError:
        exit("Building temporary directory failed")
    if(not exists(opts.output_dir)):
        makedirs(opts.output_dir)

    #open logger
    log_fh=None
    if opts.verbose:
        #append to the log file of the master process
        log_fh = open(opts.output_dir+"/"+opts.log_fp, "a", 0)
        log_fh.write("SFF file: %s\n" % opts.sff_fp)
        log_fh.write("Fasta file: %s\n" % opts.fasta_fp)
        log_fh.write("Preprocess dir: %s\n" % opts.output_dir)
        log_fh.write("Squeeze Seqs: %s\n" % opts.squeeze)
 
    (deprefixed_sff_fp, l, mapping, seqs) = \
        preprocess(opts.sff_fp, log_fh, fasta_fp=opts.fasta_fp, out_fp=tmp_dir,\
                       verbose=opts.verbose, squeeze=opts.squeeze, primer=opts.primer)
    if log_fh:
        log_fh.close()

    #move files to outputd dir
    rename(tmp_dir+"/prefix_dereplicated_averaged.sff.txt", opts.output_dir+"/prefix_dereplicated_averaged.sff.txt")
    rename(tmp_dir+"/prefix_dereplicated.fasta", opts.output_dir+"/prefix_dereplicated.fasta")
    rename(tmp_dir+"/prefix_mapping.txt", opts.output_dir+"/prefix_mapping.txt")
    rmdir(tmp_dir)

    return

if __name__ == "__main__":
    main()
