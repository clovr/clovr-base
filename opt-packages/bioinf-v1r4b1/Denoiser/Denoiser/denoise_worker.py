#!/usr/bin/env python

""" A simple client waiting for data to clean up 454 sequencing data"""

__author__ = "Jens Reeder"
__copyright__ = "Copyright 2010, Jens Reeder, Rob Knight"
__credits__ = ["Jens Reeder", "Rob Knight"]
__license__ = "GPL"
__version__ = "0.84"
__maintainer__ = "Jens Reeder"
__email__ = "jens.reeder@gmail.com"
__status__ = "Pre-release"

from os import system, remove, rename, environ
from os.path import exists
from time import sleep, time
from optparse import OptionParser

from Denoiser.settings import FLOWGRAMALI, LOOKUP

def parse_command_line_parameters(commandline_args=None):
    """ Parses command line arguments """
    usage = 'usage: %prog [options]'
    version = 'Version: %prog '+__version__
    parser = OptionParser(usage=usage, version=version)

    # A binary 'verbose' flag
    parser.add_option('-v','--verbose',action='store_true',\
                          dest='verbose', help='Print information during execution -- '+\
                          'useful for debugging [default: %default]')

    parser.add_option('-f','--file_path',action='store',\
                          type='string',dest='file_path',help='path used as prefix for worker data files'+\
                          '[REQUIRED]')

    parser.add_option('-c','--counter', action='store',\
                          type='int', dest='counter', help='Counter to start this worker with '+\
                          ' [default: %default]')

    # Define defaults
    parser.set_defaults(verbose=False, counter=0)
    
    opts,args = parser.parse_args(commandline_args)
    return opts,args

def process_data(fp, counter=0, verbose=False):
   
    if fp==None:
        raise ValueError, "process_data need file path for worker"
    #this file gets deleted by the master
    open(fp+".alive","a")
    if verbose:
        log_fh = open(fp+".log","a",0)
   
    while (exists(fp+".alive")):           
        this_round_fp = "%s_%d"% (fp, counter)
       # log_fh.write(this_round_fp+"\n")
        if (not exists(this_round_fp+".dat")):
#            log_fh.write("No data, going to sleep: %f\n" % time())
            sleep(1)
            
        else:
            if verbose:
                log_fh.write("New data arrived: %f\n"% time())
            # we have data!
            #run alignment with heapsize of 100M to reduce garbace collection time
            cmd = "%s -relscore_pairid %s %s.dat +RTS -H100M -RTS> %s.scores.tmp" \
                  % (FLOWGRAMALI, LOOKUP, this_round_fp, this_round_fp)
            system(cmd)
            
            try:
                if verbose:
                    log_fh.write(this_round_fp+"... done!\n")
                rename(this_round_fp+".scores.tmp", this_round_fp+".scores")
                remove(this_round_fp+".dat")
            except OSError:
                # If something went wrong, we log the node name and try again
                # This whole block can be deleted wehn running on a stable cluster
                # For development and troubleshooting a cluster setup it comes very handy.
                host = environ['HOSTNAME']
                if verbose:
                    log_fh.write("An Error occured while executing on %s : %f\n%s\n"\
                                     % (host, time(), cmd))
  
                #Wait a bit and try again
                #This is probably not the best way, but effective on a shaky cluster
                sleep(10)
                system(cmd)
                try:
                    remove(this_round_fp+".dat")
                    rename(this_round_fp+".scores.tmp", this_round_fp+".scores")
                except OSError:
                    if verbose:
                        log_fh.write("The error persists: %f\n"%time())
                        remove(fp+".alive") # ends while loop
                    return
            counter += 1

    if verbose:
        log_fh.close()
        remove(fp+".log")

def main(commandline_args=None):
    from sys import argv
    opts, args = parse_command_line_parameters(commandline_args)

    process_data(opts.file_path, opts.counter, opts.verbose)

if __name__ == "__main__":
    main()
