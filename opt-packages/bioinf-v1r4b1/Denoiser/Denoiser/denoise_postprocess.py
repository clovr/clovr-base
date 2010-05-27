 #!/usr/bin/env python 

__author__ = "Jens Reeder"
__copyright__ = "Copyright 2010, Jens Reeder, Rob Knight"
__credits__ = ["Jens Reeder", "Rob Knight"]
__license__ = "GPL"
__version__ = "0.84"
__maintainer__ = "Jens Reeder"
__email__ = "jens.reeder@gmail.com"
__status__ = "Pre-release"

from os import mkdir
from os.path import exists
from optparse import OptionParser
from itertools import imap
from re import compile, search

from cogent import Sequence
from cogent.parse.fasta import MinimalFastaParser

from Denoiser.utils import create_dir

def extract_read_to_sample_mapping(labels):
    """Extract a mapping from reads to sample_ids from split_libraries.

    labels: iterable if header strings

      A fasta header from split_libraries looks like this
    >S160_1 E86FECS01DW5V4 orig_bc=CAGTACGATCTT new_bc=CAGTACGATCTT bc_diffs=0
    """
    sample_id_mapping = {}

    re = compile(r'(\S+) (\S+)')
    for label in labels:
        tmatch = search(re, label)
        sample_id = tmatch.group(1)
        flowgram_id = tmatch.group(2)
        sample_id_mapping[flowgram_id] = sample_id
    
    return sample_id_mapping

#def add_sample_id(ident, sample_id_mapping):
#    """???"""
#    sample_id = sample_id_mapping[ident]
#    return("%s_%s"%(sample_id, ident))

def read_denoiser_mapping(mapping_fh):
    """read the cluster mapping file handle"""
    denoiser_mapping = {}
    for i,cluster in enumerate(mapping_fh):
        cluster, members = cluster.split(':')
        denoiser_mapping[cluster] = members.split()
    return denoiser_mapping

def sort_ids(ids, mapping):
    """sorts ids based on their cluster_size"""

    deco = [(len(mapping[id]),id) for id in ids]
    deco.sort(reverse=True)
    return [id for _,id in deco]

def post_process(fasta_fp, mapping_fp, denoised_seqs_fp, otu_picker_otu_map_fp, out_dir):
     #read in mapping from split_library file
    labels = imap(lambda (a,b): a, MinimalFastaParser(open(fasta_fp)))
    #mapping from seq_id to sample_id
    sample_id_mapping = extract_read_to_sample_mapping(labels)

    denoiser_mapping = read_denoiser_mapping(open(mapping_fp))
    #read in cd_hit otu map
    # and write out combined cotu_picker+denoiser map 
    otu_fh = open(out_dir+"/denoised_otu_map.txt","w")
    for otu_line in open(otu_picker_otu_map_fp):
        otu_split = otu_line.split()
        
        otu = otu_split[0]
        ids = otu_split[1:]
        
        get_sample_id = sample_id_mapping.get
        #concat lists
        #make sure the biggest one is first for pick_repr
        all_ids = sort_ids(ids, denoiser_mapping)
        all_ids.extend(sum([denoiser_mapping[id] for id in ids], []))
        try:
            otu_fh.write("%s\t" % otu +
                         "\t".join(map(get_sample_id, all_ids))+"\n")
        except TypeError:
            #get returns Null if denoiser_mapping id not present in sample_id_mapping
            print "Found id in denoiser output, which was not found in %s. Wrong file?"\
                % fasta_fp
            exit()

    fasta_out_fh = open(out_dir+"/denoised_all.fasta","w")
    for label, seq in  MinimalFastaParser(open(denoised_seqs_fp)):
        id = label.split()[0]
        newlabel = "%s %s" %(sample_id_mapping[id], id)
        fasta_out_fh.write(Sequence(name= newlabel, seq=seq).toFasta()+"\n")

def parse_command_line_parameters(commandline_args=None):
    """ Parses command line arguments """

    version = 'Version: %prog '+ __version__
    example_usage = """

Example:
Combine denoiser output with output of QIIME OTU picker, put results into Outdir:

%prog -f seqs.fna -d denoised.fasta -m denoiser_mapping.txt -p cdhit_picked_otus/denoised_otus.txt -v -o Outdir
"""
    usage = 'usage: %prog [options] -i data.sff.txt' + example_usage
    parser = OptionParser(usage=usage, version=version)
 
    parser.add_option('-v','--verbose',action='store_true',\
                          dest='verbose', help='Print information during execution '+\
                          'into log file [default: %default]')

    parser.add_option('-m','--map_file',action='store',\
                          type='string',dest='denoiser_map_file',
                      help='path to denoiser mapping file '+\
                          '[default: %default]')

    parser.add_option('-p','--otu_picker_map_file',action='store',\
                          type='string',dest='otu_picker_map_file',
                      help='path to OTU picker mapping file '+\
                          '[REQUIRED]')

    parser.add_option('-f','--fasta_fp',action='store',\
                          type='string',dest='fasta_fp',help='path to fasta input file, '+\
                          'output of split_libraries.py'+\
                          ' [REQUIRED]')

    parser.add_option('-d','--denoised_fasta_fp',action='store',\
                          type='string',dest='denoised_fasta_fp',
                      help='path to denoised fasta file '+\
                          '[REQUIRED]')

    parser.add_option('-o','--output_dir',action='store',\
                          type='string',dest='output_dir',help='path to output'+\
                          ' directory [default: %default]')

    # Define defaults
    parser.set_defaults(verbose=False, denoiser_map_file="denoiser_mapping.txt",
                        output_dir="Denoiser_out_otu_picked/")
    
    opts,args = parser.parse_args(commandline_args)
   
    #check for missing files
    required_files = [opts.denoiser_map_file, opts.otu_picker_map_file,
                      opts.fasta_fp, opts.denoised_fasta_fp]
    if (not all(required_files) or not all(map(exists, required_files))):
        parser.error('Missing input files.')
    return opts,args

def main(commandline_args=None):
    from sys import argv

    opts, args = parse_command_line_parameters(commandline_args)

    create_dir(opts.output_dir, fail_on_exist=False)
           
    post_process(opts.fasta_fp, opts.denoiser_map_file, opts.denoised_fasta_fp,
                 opts.otu_picker_map_file, opts.output_dir)
   
if __name__ == "__main__":
    main()
