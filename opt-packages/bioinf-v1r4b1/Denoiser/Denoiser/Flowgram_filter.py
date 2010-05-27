#!/usr/bin/env python 

"""Functions to filter and crop flowgrams"""

__author__ = "Jens Reeder"
__copyright__ = "Copyright 2010, Jens Reeder, Rob Knight"
__credits__ = ["Jens Reeder", "Rob Knight"]
__license__ = "GPL"
__version__ = "0.84"
__maintainer__ = "Jens Reeder"
__email__ = "jens.reeder@gmail.com"
__status__ = "Pre-release"

from sys import stdout
from re import compile, search
from itertools import imap
from collections import defaultdict

from cogent.app.util import get_tmp_filename
from cogent.parse.fasta import MinimalFastaParser
from cogent.parse.flowgram_parser import lazy_parse_sff_handle
from cogent.parse.flowgram import Flowgram

DEFAULT_KEYSEQ = "TCAG"

def writeSFFHeader(header, fh, num=None):
    """writes the Common header of a sff.txt file.

    header: the header of an sff file as returned by the sff parser.
    
    fh: output file handle
    
    num: number of flowgrams to be written in the header.
          Note that his number should match the final number, if 
          the resulting sff.txt should be consistent.
          """

    lines = ["Common Header:"]
    if (num !=None):
        header["# of Flows"] = num

    lines.extend(["  %s:\t%s" % (param, header[param]) \
                      for param in header])
    fh.write("\n".join(lines)+"\n\n")

def filterSFFFile(handle, filter_list, out_fh):
    """Filters all flowgrams in handle with filter.

    handle: an open sff.txt file handle
    
    filter_list: list of filters to be applied on sff.txt file
    
    out_fh: output file handle

    returns: number of flowgrams in filtered out file
    """
   
    (flowgrams, header) = lazy_parse_sff_handle(handle)
    writeSFFHeader(header, out_fh)

    l = 0
    for f in flowgrams:
        passed = True 
        for filter in filter_list:
            passed = passed and filter(f)            
            if not passed:
                #bail out
                break
        if (passed):
            out_fh.write(f.createFlowHeader()+"\n")
            l += 1
    return l

def withinLength(flowgram, minlength=0, maxlength=400):
    """Checks if the (quality trimmed) seq of flowgram is within a specified length.

    flowgram: flowgram to check
    
    minlenght: minimal required length
    
    maxlenght: maximal allowed length
    """
    seq = flowgram.toSeq()
    l = len(seq)
    return (l >= minlength and l <= maxlength)

def truncate_flowgrams_in_SFF(handle, outhandle=None, outdir="/tmp/",
                              barcode_mapping=None, primer=None):
    """Truncate flowgrams at low quality 3' end and strip key+primers.

    handle: an open file handle to a s.sff.txt file

    outhandle: output file handle, can be None

    outdir: directory where random file will be created if outhandle is None

    barcode_mapping: dictionary mapping of read ids to barcode seqs.
                     The barcode seq will be truncated of the 5' end of the read
                     
    primer: primer sequence that will be truncated of the 5' end of the read
"""
    
    out_filename = ""
    if not outhandle:        
        out_filename = get_tmp_filename(tmp_dir=outdir, prefix="trunc_sff",
                                        suffix = ".sff.txt")
        outhandle = open(out_filename, "w")

    (flowgrams, header) = lazy_parse_sff_handle(handle)
    writeSFFHeader(header, outhandle)

    l = 0
    for f in flowgrams:
        qual_trimmed_flowgram = f.getQualityTrimmedFlowgram()
        
        if barcode_mapping:
            if barcode_mapping.has_key(f.Name):
                trunc_flowgram = qual_trimmed_flowgram.getPrimerTrimmedFlowgram(\
                    primerseq = DEFAULT_KEYSEQ+barcode_mapping[f.Name]+primer)
            else:
                continue
        else: 
            prim = DEFAULT_KEYSEQ
            if primer:
                prim += primer
            trunc_flowgram = qual_trimmed_flowgram.getPrimerTrimmedFlowgram(\
                primerseq = prim)

        if(trunc_flowgram!=None):
            outhandle.write(trunc_flowgram.createFlowHeader() +"\n")
            l += 1
    return (out_filename, l)

def cleanup_sff(sff_fh, outhandle=None, outdir = "/tmp"):
    """Clean a sff file and returns name of clean file and number of clean flowgrams.
    
    outhandle: handle flowgrams will be written to if set, can be stdout

    outdir: if handle is not set, random file will be created in outdir

    TODO: this has to be linked with the qual filters in split_libraries
    """

    clean_filename = ""
    if not outhandle:        
        clean_filename = get_tmp_filename(tmp_dir=outdir, prefix="cleanup_sff",
                                          suffix = ".sff.txt")
        outhandle = open(clean_filename, "w")
        
    l = filterSFFFile(sff_fh, [lambda f: withinLength(f,150,400),
                                lambda f: f.hasProperKey()],
                       outhandle)
    return (clean_filename,l)


def split_sff(sff_file_handle, map_file_handle, outdir="/tmp/"):
    """Splits an sff.txt file on barcode/mapping file."""
    
    (flowgrams, header) = lazy_parse_sff_handle(sff_file_handle)

    (inverse_map, map_count) = build_inverse_barcode_map(MinimalFastaParser(map_file_handle))
    
    filenames = []
    #we might have many barcodes and reach python open file limit
    # therefor we go the slow way and open and close files each time
    #First set up all files with the headers only
    for barcode_id in map_count.keys():
        fh = open(outdir+barcode_id, "w")
        writeSFFHeader(header, fh, map_count[barcode_id])
        fh.close()
        filenames.append(outdir+barcode_id)
    #Then direct each flowgram into its barcode file
    for f in flowgrams:
        if inverse_map.has_key(f.Name):
            barcode_id = inverse_map[f.Name]
            fh = open(outdir+barcode_id, "a")
            fh.write(f.createFlowHeader()+"\n")
    return filenames
        
def build_inverse_barcode_map(seqs):
    """Build a map from fasta header from split_libraries.

    seqs: a list of (label, seq)  pairs

    Returns: mapping of flowgram ID to sampleID and a sample count

    A fasta header from split_libraries looks like this
    >S160_1 E86FECS01DW5V4 orig_bc=CAGTACGATCTT new_bc=CAGTACGATCTT bc_diffs=0
    """
    inverse_map= {}
    map_count = defaultdict(int)
    for (label,seq) in seqs:
        (map_id, seq_id) = label.split()[:2]
        map_id = map_id.split("_")[0]
        inverse_map[seq_id] = map_id
        map_count[map_id] += 1
    
    return (inverse_map, map_count)

def extract_barcodes_from_mapping(labels):
    """extract barcodes from split_libraries fasta headers.

    Returns a dictionary{flowgram_id:barcode_seq}
    """
    barcodes = {}

    #use \w* to allow for non barcoded reads
    re = compile(r'(\w+) (\w+) orig_bc=(\w*) new_bc=\w* bc_diffs=\d+')
    for label in labels:
        tmatch = search(re, label)
        flowgram_id = tmatch.group(2)
        barcode = tmatch.group(3)

        barcodes[flowgram_id] = barcode

    return barcodes

if __name__ == '__main__':
    """Example usage: Flowgram_filter.py file.sff.txt split_libraries_seq.fasta"""
    from sys import argv
    
    labels = imap(lambda (a,b): a, MinimalFastaParser(open(argv[2])))
    barcode_mapping = extract_barcodes_from_mapping(labels)
    (trunc_filename, l) = truncate_flowgrams_in_SFF(open(argv[1]), barcode_mapping=barcode_mapping)
    print "File written to "+trunc_filename
