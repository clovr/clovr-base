#!/usr/bin/env python
from __future__ import division

"""Various helper functions."""

__author__ = "Jens Reeder"
__copyright__ = "Copyright 2010, Jens Reeder, Rob Knight"
__credits__ = ["Jens Reeder", "Rob Knight"]
__license__ = "GPL"
__version__ = "0.84"
__maintainer__ = "Jens Reeder"
__email__ = "jens.reeder@gmail.com"
__status__ = "Pre-release"

from os import remove, makedirs
from os.path import exists, isdir
from collections import defaultdict
from re import sub
from time import sleep

from cogent import Sequence
from cogent.app.util import get_tmp_filename
from cogent.util.misc import app_path
from cogent.app.util import ApplicationNotFoundError
from cogent.parse.flowgram_parser import lazy_parse_sff_handle

from Denoiser.Flowgram_filter import writeSFFHeader

class FlowgramContainerFile():
    """A Flogram container using a file.

    This class can be used to store intermediate flowgram files on disk.
    Slower, but keeps a very low memory footprint.
    """
    
    def __init__(self, header, outdir="/tmp/"):
        #set up output file 
        self.filename = get_tmp_filename(tmp_dir=outdir, prefix="fc",
                                         suffix =".sff.txt")
        self.fh = open(self.filename, "w")
        writeSFFHeader(header, self.fh)

    def add(self, flowgram):
        self.fh.write(flowgram.createFlowHeader() +"\n")
 
    def __iter__(self):
        #reset to start of file
        self.fh.close()
        (self.flowgrams, self.header) = lazy_parse_sff_handle(open(self.filename))        
        return self.flowgrams

    def __del__(self):
        remove(self.filename)
    
class FlowgramContainerArray():
    """A Flogram container using a simple list.

    Keeps all flowgrams in memory. Faster, but needs a lot of memory.
    """
    
    def __init__(self):
         self.data=[]

    def add(self, flowgram):
        self.data.append(flowgram)
                        
    def __iter__(self):
        return self.data.__iter__()

def make_stats(mapping):
    """Calculates some statistics.
    
    mapping: The prefix mapping dict
    """
    stats = ["Clustersize\t#"]
    counts = defaultdict(int)
    for key in mapping.keys():
         counts[len(mapping[key])] += 1
    
    keys = counts.keys()
    keys.sort()
    for key in keys:
        stats.append("%d:\t\t%d"%(key+1, counts[key]))
    return "\n".join(stats)

def get_representatives(mapping, seqs):
    """Returns representative seqs.

    mapping: The prefix mapping dict
    
    seqs_fh: An openened Fasta filehandle
    """
    for (label,seq) in seqs:
        if(mapping.has_key(label)):            
            seq  = Sequence(name = "%s: %d" %(label, len(mapping[label])+1),
                            seq = seq)
            yield seq
      
def store_mapping(mapping, outdir, prefix ):
    """Store the mapping of denoised seq ids to input ids."""
    fh = open(outdir+"/"+prefix+"_mapping.txt", "w")
    for (key, valuelist) in mapping.iteritems():
        fh.write("%s:"%key)
        for v in valuelist:
            fh.write("\t%s" %v)            
        fh.write("\n")
    fh.close()

def store_clusters(mapping, sff_fp, outdir="/tmp/", store_members=False):
    """Stores fasta and flogram file for each cluster."""

    # get mapping read to cluster
    invert_map = invert_mapping(mapping)
    (flowgrams, header) = lazy_parse_sff_handle(open(sff_fp))
    
    leftover_fasta_fh = open(outdir + "/singletons.fasta", "w")
    centroids = []
    for f in flowgrams:

        try:
            key = invert_map[f.Name]
        except KeyError:
            # this flowgram has not been clustered
            continue
        if (len(mapping[key])==0):
            # do not store singletons in a separate cluster
            leftover_fasta_fh.write(f.toFasta()+"\n")    
            continue
        elif(mapping.has_key(f.Name)):
            #save as a centroid
            centroids.append((len(mapping[f.Name])+1, f.Name,  f.toSeq()))

        if (store_members):
            flows_fh = open(outdir+key+".flows", "a")
            fasta_fh = open(outdir+key+".fasta", "a")
            flows_fh.write("%s\n" % f)
            fasta_fh.write(f.toFasta()+"\n")
            fasta_fh.close()
            flows_fh.close()

    leftover_fasta_fh.close()    

    #sort and store ordered by cluster_size
    centroids.sort(reverse=True)
    centroid_fh       = open(outdir + "/centroids.fasta", "w")
    for size,name,seq  in centroids:
        centroid_fh.write(">%s | cluster size: %d \n%s\n" %
                           (name, size, seq))
    centroid_fh.close()

def squeeze_seq(seq):
    """Squeezes consecutive identical nucleotides to one."""

    return sub(r'([AGCTacgt])\1+', '\\1', seq)
 
def waitForFile(filename, interval=10, test_mode=False):
    """Puts the process to sleep until the file is there.

    filename: file to wait for
    
    interval: sleep interval in seconds
    
    test_mode: raise Exception instead of going to sleep
    """
    while(not exists(filename)):
        if test_mode:
            raise RuntimeWarning
        sleep(interval)

def waitForClusterIds(ids, interval = 10):
    """Puts process to sleep until jobs with ids are done.

    ids:  list of ids to wait for

    interval: time to sleep in seconds
    """
    if (app_path("qstat")):
        for id in ids:
            while(getoutput("qstat %s" % id).startswith("Job")):
                sleep(interval)
    else:
        raise ApplicationNotFoundError,"qstat not available. Is it installed?\n"+\
            "This test may fail if not run on a cluster."

def initFlowgramFile(filename=None, n=0, l=400, prefix = "/tmp/" ):
    """Opens a file in plain flowgram format and writes header information.

    filename: name of output file

    n: number of flowgrams in the file

    l: length of each flowgram in the file

    prefix: directory prefix

    Returns an open filehandle and the file name.
    """
    
    if (filename == None ):
        filename = get_tmp_filename(tmp_dir = prefix, suffix=".dat")
    
    fh = open(filename,"w")
    fh.write("%d %d\n" % (n, l))
    return (fh, filename)

def appendToFlowgramFile(identifier, flowgram, fh, trim = False):
    """Adds one flowgram to an open plain flowgram file.

    id: identifier of this flowgram

    flowgram: the flowgram itself

    fh: filehandle to write in
    
    trim: Boolean flag for quality trimming flowgrams 
    """

    if trim:
        flowgram = flowgram.getQualityTrimmedFlowgram()

    #store space separated string representation of flowgram
    if (not hasattr(flowgram, "spaced_flowgram")):
        spaced_flowgram_seq = " ".join(map(str, flowgram.flowgram))
        flowgram.spaced_flowgram = spaced_flowgram_seq
    else:
        spaced_flowgram_seq = flowgram.spaced_flowgram

    fh.write("%s %d %s\n" % (identifier, len(flowgram), spaced_flowgram_seq))

def read_signal_probs(file):
    """Read and check the signal probabilty file""" 
    f = open(file)
    lines = f.readlines()
    f.close()
    
    flow_probs = defaultdict(list)
    flow_logs = defaultdict(list)

    for line in lines:
        if line.startswith('#'):
            continue
        for i, num in enumerate(line.strip().split()[2::2]):
	    flow_probs[i].append(float(num))
        for i, num in enumerate(line.strip().split()[1::2]):
	    flow_logs[i].append(float(num))

    for p in flow_probs:
        s = sum(flow_probs[p])
        flow_probs[p] = [i/s for i in  flow_probs[p]]

    return (flow_probs, flow_logs)

def create_dir(dir_name, fail_on_exist=True):
    """Open a dir safely and fail meaningful.

    dir_name: name of directory to create

    fail_on_exist: if true raise an error if dir already exists
    
    returns 1 if directory already existed, 0 otherwise

    Note: Depending  of how thorough we want to be we could add tests,
          e.g. for testing actual write permission in an existing dir
          Copied from qiime.util
    """

    if exists(dir_name):
        if isdir(dir_name):
            #dir is there
            if fail_on_exist:
                raise OSError,"Directory already exists: %s" % dir_name
            else:
                return 1
        else:
            #must be file with same name
            raise OSError,"File with same name as dir_name exists: %s" % dir_name
    else:
        #no dir there, make it
        try:
            makedirs(dir_name)
        except OSError:
            #re-raise error, but slightly more informative 
            raise OSError,"Could not create output directory: %s" % dir_name
        return 0

def invert_mapping(mapping):
    """Inverts a dictionary mapping.
    
    Keys are inserted as a special case:
    Ex: {1:(2,3,4)} ==>{1:1, 2:1, 3:1, 4:1} 

    Note: This will overwrite an entry if it is redundant.
    """
    
    invert_map = {}
    for key in mapping.keys():
        invert_map[key] = key
        for id in mapping[key]:
            invert_map[id] = key
    return invert_map
