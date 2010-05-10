#!/usr/bin/env python 

"""Several clustering methods to clean up 454 sequencing data"""

__author__ = "Jens Reeder"
__copyright__ = "Copyright 2010, Jens Reeder, Rob Knight"
__credits__ = ["Jens Reeder", "Rob Knight"]
__license__ = "GPL"
__version__ = "0.84"
__maintainer__ = "Jens Reeder"
__email__ = "jens.reeder@gmail.com"
__status__ = "Pre-release"

from os import system, remove, environ, popen, makedirs, rename
from sys import exit
from os.path import exists
from collections import defaultdict
from itertools import izip, imap, ifilter

from cogent.app.util import get_tmp_filename, ApplicationNotFoundError
from cogent.parse.flowgram_parser import lazy_parse_sff_handle
from cogent.parse.flowgram import Flowgram, seq_to_flow
from cogent.parse.flowgram_collection import FlowgramCollection

from Denoiser.utils import waitForFile, initFlowgramFile, appendToFlowgramFile,\
    FlowgramContainerFile, FlowgramContainerArray, make_stats, store_mapping,\
    store_clusters,create_dir

from Denoiser.cluster_utils import setup_workers, adjust_workers, stop_workers,\
                                   check_workers
from Denoiser.Flowgram_filter import writeSFFHeader
from Denoiser.preprocess import preprocess, preprocess_on_cluster,\
     read_preprocessed_data
from Denoiser.settings import *

def get_flowgram_distances_on_cluster(id, flowgram, flowgrams, fc, ids, num_cores,
                                      num_flows, outdir, workers, counter=0):
    """Computes distance scores of flowgram to all flowgrams in parser.

    id: The flowgram identifier, also used to name intermediate files
    
    flowgram: This flowgram is used to filter all the other flowgrams

    flowgrams: iterable filehandle of flowgram file

    fc: a sink of flowgrams, which serves as source in the next round

    ids: list of flowgram ids tht should be used from flowgrams

    num_cores: number of cpus

    num_flows: Number of flows in parser

    outdir: directory for intermediate files
    """

    if not CLUSTER_JOBS_SCRIPT or not exists(CLUSTER_JOBS_SCRIPT):
        raise ApplicationNotFoundError, "CLUSTER_JOBS_SCRIPT in setting.py no set correctly!"

    #if using from future import division this has to be checked
    per_core = max(MIN_PER_CORE, (num_flows/num_cores)+1)
    names = []
    scores = []
    resultfiles = []
    
    #Need to call this here, since we iterate over the same iterator repeatedly.
    #Otherwise the call in ifilter will reset the iterator by implicitely  calling __iter__.
    flowgrams_iter=flowgrams.__iter__()    
    #prepare input files and commands
    for i in range (num_cores):
        (fh, filename) = initFlowgramFile(prefix = outdir, n=per_core)
        filename = filename.lstrip('\"')
        filename = filename.rstrip('\"')
        if(i*per_core> num_flows):
            #create a file with only the header and master flow
            #This should be made more robust, but needs change in the worker as well as in the alignment tool  
            appendToFlowgramFile(id, flowgram, fh)
            fh.close()
            #show the input file to the worker
            data_fp = "%s_%d.dat"%(workers[i],counter)
            data_fp = data_fp.replace('"','')
            rename(filename, data_fp)
            break

        #add master flowgram to file first
        appendToFlowgramFile(id, flowgram, fh)
        # Then add all others which are still valid, i.e. in ids
        for (k,f) in (izip (range(per_core),
                            ifilter(lambda f: ids.has_key(f.Name), flowgrams_iter))):
            fc.add(f)
            appendToFlowgramFile(k, f, fh, trim=False)
            names.append(f.Name)
        fh.close()
        
        #show the input file to the worker
        data_fp = "%s_%d.dat"%(workers[i],counter)
        data_fp = data_fp.replace('"','')
     
        rename(filename, data_fp)

    #now collect all results    
    for i in range (num_cores):
        if(i*per_core> num_flows):
            break
        resultfile = "%s_%d.scores" % (workers[i],counter) 
        resultfile = resultfile.replace('"','')
        waitForFile(resultfile,1)
          
        fh = open(resultfile)
        this_cores_scores = [map(float, (s.split())) for s in fh if s != "\n"]
        scores.extend(this_cores_scores)
        remove(resultfile)

    return (scores, names, fc) 

def get_flowgram_distances(id, flowgram, flowgrams, fc, ids, outdir):
    """Computes distance scores of flowgram to all flowgrams in parser.

    id: The flowgram identifier, also used to name intermediate files
    
    flowgram: This flowgram is used to filter all the other flowgrams

    flowgrams: iterable filehandle of flowgram file
    
    fc: a sink for flowgrams, either a FlowgramContainerArray or
        FlowgramContainerFile object
    
    ids: list of ids of flowgrams in flowgrams that should  be aligned

    outdir: directory for intermediate files
    """

    # File that serves as input for external alignment program
    (fh, tmpfile) = initFlowgramFile(prefix = outdir)
    appendToFlowgramFile(id, flowgram, fh)

    k = 0
    names = []
    for f in flowgrams:
        if(ids.has_key(f.Name)):
            fc.add(f)
            appendToFlowgramFile(k, f, fh, trim=False)
            k += 1
            names.append(f.Name)
    fh.close()

    #run alignment with heap size of 100M to reduce garbace collection time
    scores_fh = popen("%s -relscore_pairid %s %s +RTS -H100M -RTS" % (FLOWGRAMALI, LOOKUP, tmpfile), 'r')
    scores = [map(float, (s.split())) for s in scores_fh if s != "\n"]
    remove(tmpfile)

    return (scores, names, fc)

def filterWithFlowgram(id, flowgram, flowgrams, header, ids, num_flows, bestscores, log_fh,
                       outdir="/tmp/", threshold=3.75, num_cpus=32,
                       fast_method=True, on_cluster = False, mapping=None,
                       verbose=False, pair_id_thresh=0.97, workers=[], counter=0):
    """Filter all files in flows_filename with flowgram and split according to threshold.

    id: The flowgram identifier, also used to name intermediate files

    flowgram: This flowgram is used to filter all the other flowgrams

    flows_filename: File containing the flowgrams to be filtered
    
    num_flows: Number of flows in file flows_filename

    bestscores: dictionary that stores for each unclustered flowgram the best
                score it has to to one of the centroids previously seen
                and the id of the centroid. Used in the second denoising phase.

    outdir: directory where intermediate and result files go

    threshold: Filtering threshold

    num_cpus: number of cpus to run on, if on_cluster == True

    fast_method: Boolean value for fast denoising with lots of memory
    
    on_cluster: Boolean flag for local vs cluster

    Returns filename of file containing all non-filtered flows and the number of flows
    """
    if verbose:
        log_fh.write("Filtering with %s: %d flowgrams\n" % (id, num_flows))

    #set up the flowgram store
    if (not fast_method):
        fc = FlowgramContainerFile(header, outdir)
    else:
        fc = FlowgramContainerArray()

    #calculate distance scores
    if on_cluster: 
        (scores, names, flowgrams) =\
            get_flowgram_distances_on_cluster(id, flowgram, flowgrams, fc, ids, num_cpus,
                                              num_flows, outdir=outdir, workers=workers, counter=counter) 
    else:
        (scores, names, flowgrams) =\
            get_flowgram_distances(id, flowgram, flowgrams, fc, ids, outdir=outdir)

    #shortcut for non-matching flowgrams
    survivors = filter(lambda (a,b): a<threshold or b>=pair_id_thresh, scores)
    if(len(survivors)==0):
        #put it in its own cluster
        # and remove it from any further searches
        if (bestscores.has_key(id)):
            del(bestscores[id])
        del(ids[id])            
        return (flowgrams, num_flows-1)
        
    if (not mapping.has_key(id)):
        #centroids from pyronoise have to be inserted manually
        #DO we need this anymore??
        mapping[id] = []

    # Do the filtering
    non_clustered_ctr = 0 
    for ((score, pair_id), name) in zip(scores, names):
        if (score < threshold or name==id or pair_id>=pair_id_thresh):
            #make sure the original flowgram gets into this cluster
            del(ids[name])
            if (bestscores.has_key(name)):
                del(bestscores[name])
            if(id!=name):
                #update the mapping information
                mapping[id].extend(mapping[name])
                mapping[id].append(name)
                #delete the old cluster from the mapping 
                del(mapping[name])
        else:       
            non_clustered_ctr += 1
            #keep track of the best match of this guy to any centroid
            if (not bestscores.has_key(name) or score < bestscores[name][1]):
                bestscores[name] = (id, score)
   
    assert(len(ids) == non_clustered_ctr)
    assert(len(bestscores) == non_clustered_ctr)
    return (flowgrams, non_clustered_ctr)

def secondary_clustering(sff_file, mapping, bestscores, log_fh,\
                             threshold=4.5, outdir="/tmp/", verbose=False):
       """Clusters sequences based on their best distance to any of the centroids.

       Does not actually compute distances but uses the results of the first
       phase stored in bestscores.

       
       sff_file: name of unclustered flowgram file
       
       mapping: preliminary mapping file, dictionary of ids to list of ids

       bestscores: dictionary that stores for each unclustered flowgram the best
                score it has to to one of the centroid previously seen
                and the id of the centroid. Used in the second denoising phase.

       threshold: Secondary clustering threshold.

       outdir: directory for result files from phase 1

       """
       if(len(bestscores)==0):
           #Either all sequence are already clustered or
           # we had no seq exceeding the bail out limit
           return

       (flowgrams, header) = lazy_parse_sff_handle(open(sff_file))
   
       counter = 0
       for f in flowgrams:
           (id, score) = bestscores[f.Name] 
           if (score < threshold):
               counter += 1
               #update the mapping information
               mapping[id].extend(mapping[f.Name])
               mapping[id].append(f.Name)
               del(mapping[f.Name])               
       if verbose:
           log_fh.write("Secondary clustering removed %d flowgrams\n" % counter)

def greedy_clustering(sff_fp, seqs, cluster_mapping, outdir, num_flows,
                      log_fh, num_cpus=1, on_cluster=False,
                      bail_out=1, pair_id_thresh=0.97, verbose=False,
                      threshold=3.75, queue="friendlyq",fast_method=True):
    """second clustering phase of denoiser.

    
    sff_fp: flowgram file
    seqs: fasta seqs corresponding to sff_fp
    cluster_mapping: preliminary cluster mapping from phase I
    outdir: output directory
    num_flows: number of flowgrams in sff_fp (need to now before parsing sff_fp)
    log_fh: write verbose info to log_fh if set
    num_cpus:number of cpus to use of on_cluster ==True
    on_cluster: run in paralel if True
    bail_out: stop clustering with first cluster having bail_out members
    pair_id_thresh: always cluster flowgrams whose flowgram alignment implies a seq
                     identity of pair_id_thresh or higher
    verbose: be verbose or not
    threshold: low clustering threshold for phase II
    queue: name of the queue (currently not in use)
    fast_method: use more memory intensive but faster method
    """

    bestscores   = {}
    cluster_size = defaultdict(int)
  
    (flowgrams, header) = lazy_parse_sff_handle(open(sff_fp))
    l = num_flows

    workers=None
    if on_cluster:
        workers = setup_workers(num_cpus, outdir, queue, verbose=verbose) 

    # ids  stores all the active sequences(
    ids = seqs
    #old_flows_fp = sff_fp
    counter = 0
    #sort cluster_mapping by cluster size  
    for key in sorted(cluster_mapping.keys(), cmp = lambda a,b: cmp(len(a), len(b)),
                      key=lambda k: cluster_mapping[k], reverse=True):

        if(not cluster_mapping.has_key(key)):
            #this guy already has been clustered
            continue
        
        prefix_clustersize=len(cluster_mapping[key])      
        #abort greedy first phase 
        if(prefix_clustersize < bail_out):
            break

        # Do not take bad sequences as cluster seeds
        if('N' in seqs[key]):
            continue
        
        #check and delete workers if no longer needed
        if on_cluster:
            num_cpus = adjust_workers(l, num_cpus, workers, log_fh)
            #check for dead workers
            check_workers(workers, log_fh)
        
        ideal_flow = seq_to_flow(seqs[key])
        (new_flowgrams, newl) = filterWithFlowgram(key, ideal_flow, flowgrams, header, ids,
                                                   l, bestscores, log_fh, outdir,
                                                   on_cluster=on_cluster,
                                                   num_cpus=num_cpus,
                                                   fast_method=fast_method, 
                                                   mapping=cluster_mapping,
                                                   verbose=verbose,
                                                   threshold=threshold,
                                                   pair_id_thresh=pair_id_thresh,
                                                   workers=workers, counter=counter)
        cluster_size[id] +=  (l-newl)
        l = newl
        counter += 1
        flowgrams = new_flowgrams
        if(newl==0):
            #all flowgrams clustered
            break
    if on_cluster:
        stop_workers(workers, log_fh)

    #write all remaining flowgrams into file for next step
    #TODO: might use abstract FlowgramContainer here as well
    non_clustered_filename = get_tmp_filename(tmp_dir=outdir, prefix="ff",
                                              suffix =".sff.txt")
    non_clustered_fh = open(non_clustered_filename, "w")
    writeSFFHeader(header, non_clustered_fh)
    for f in flowgrams:
         if (ids.has_key(f.Name)):
              non_clustered_fh.write(f.createFlowHeader() +"\n")
              
    return(non_clustered_filename, bestscores)


def denoise_seqs(sff_fp, fasta_fp, tmpoutdir, preprocess_fp=None, cluster=False, num_cpus=2, squeeze=True,
                 percent_id=0.97, bail=1, primer="", low_cutoff=3.75, high_cutoff=4.5, log_fp="denoiser.log",
                 low_memory=False, verbose=False):

    #switch of buffering for log file
    if verbose:
        log_fh = open(tmpoutdir+"/"+log_fp, "w", 0)
    else:
        log_fh = None
        
    if verbose:
        log_fh.write("SFF file: %s\n" % sff_fp)
        log_fh.write("Fasta file: %s\n" % fasta_fp)
        log_fh.write("Preprocess dir: %s\n" % preprocess_fp)
        log_fh.write("Primer sequence: %s\n" % primer)
        log_fh.write("Cluster: %s\n" % cluster)
        log_fh.write("Num CPUs: %d\n" % num_cpus)
        log_fh.write("Squeeze Seqs: %s\n" % squeeze)
        log_fh.write("tmpdir: %s\n" % tmpoutdir)
        log_fh.write("percent_id threshold: %.2f\n" % percent_id)
        log_fh.write("Minimal sequence coverage for first phase: %d\n" %bail)
        log_fh.write("Low cut-off: %.2f\n" % low_cutoff)
        log_fh.write("High cut-off: %.2f\n\n" % high_cutoff)

    # here we go ...
    # Phase I - clean up and truncate input sff
    if(preprocess_fp):
        # we already have preprocessed data, so use it
        (deprefixed_sff_fp, l, mapping, seqs) = read_preprocessed_data(preprocess_fp)
    elif(cluster):
        preprocess_on_cluster(sff_fp, log_fp, fasta_fp=fasta_fp,
                              out_fp=tmpoutdir, verbose=verbose,
                              squeeze=squeeze, primer=primer)
        (deprefixed_sff_fp, l, mapping, seqs) = read_preprocessed_data(tmpoutdir)
    else:
        (deprefixed_sff_fp, l, mapping, seqs) = \
        preprocess(sff_fp, log_fh, fasta_fp=fasta_fp, out_fp=tmpoutdir,
                   verbose=verbose, squeeze=squeeze)

    #preprocessor writes into same file, so better jump to end of file
    if verbose:
        log_fh.close()
        log_fh = open(tmpoutdir+"/"+log_fp, "a", 0)
        
    # phase II:
    # use prefix map based clustering as initial centroids and greedily add flowgrams to clusters
    # with a low threshold
    (new_sff_file, bestscores) = \
        greedy_clustering(deprefixed_sff_fp, seqs, mapping, tmpoutdir, l, log_fh,
                          num_cpus=num_cpus, on_cluster=cluster,
                          bail_out=bail, pair_id_thresh=percent_id,
                          threshold=low_cutoff,
                          verbose=verbose, #queue=queue,
                          fast_method= not low_memory)

    # phase III phase:
    # Assign seqs to nearest existing centroid with high threshold
    secondary_clustering(new_sff_file, mapping, bestscores, log_fh, outdir=tmpoutdir,
                         verbose=verbose, threshold=high_cutoff)
    remove(new_sff_file)
    if (verbose):
        log_fh.write("Finished clustering\n")
        log_fh.write("Writing Clusters\n")
        log_fh.write(make_stats(mapping)+"\n")
    store_clusters(mapping, deprefixed_sff_fp, tmpoutdir)
    store_mapping(mapping, tmpoutdir,"denoiser")
