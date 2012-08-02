#!/usr/bin/env python

"""script for finding phylogenetically conserved
markers from a multipe sequence alignment"""

import sys
import os
import subprocess
import tempfile
import string
import itertools
import threading
import optparse

from Bio import SeqIO
from Bio.Blast import NCBIXML

from igs.utils import functional as func
from igs.utils import logging

from igs.threading import functional as p_func

class Increments:
    def __init__(self, start, increment):
        self.state = start
        self.p_start = start
        self.p_increment = increment

    def next(self):
        self.state += self.p_increment
        return self.state

    def reset(self):
        self.state = self.p_start

record_count_1 = Increments(1, 1)
record_count_2 = Increments(1, 1)
        

def sliding_window(sequence, frag_length, step_size=5):
    """cuts up sequence into a given length"""
    numOfChunks = (len(sequence) - frag_length) + 1
    for i in range(0, numOfChunks, step_size):
        yield sequence[i:i + frag_length]

def split_sequence_by_window(input_file, step_size, frag_length):
    """cuts up fasta sequences into given chunks"""
    infile = open(input_file, "rU")
    first_record = list(itertools.islice(SeqIO.parse(infile,"fasta"), 1))[0]
    return sliding_window(first_record.seq, frag_length, step_size)

def split_quality_values(qual_file, step_size, frag_length):
    infile = open(qual_file, "rU")
    instring = infile.readlines()
    infile.close()
    qual_reads = sliding_window(','.join(instring), frag_length, step_size)
    return qual_reads

def write_qualities(qual_reads):
    """write shredded quality files to disk"""
    handle = open("quals_shredded.txt", "w")
    for read in qual_reads:
        print >> handle, read
    handle.close()

def write_sequences(reads):
    """write shredded fasta sequences to disk"""
    handle = open("seqs_shredded.txt", "w")
    for read in reads:
        print >> handle, ">%d\n%s" % (record_count_1.next(), read)
    handle.close()

def split_read(input_file):
    """insert gaps into quality files - needed to put into array"""
    handle = open("padded_quals.txt", "w")
    qual_lines = open(input_file, "rW")
    for line in qual_lines:
        line = line.strip()
        print >> handle, ' '.join(line)

    handle.close()

def sum_qual_reads(input_file):
    """adds up quality values for each sequence"""
    handle = open("summed_qualities.txt", "w")
    padded_qual_lines = open(input_file, "rU")
    for line in padded_qual_lines.xreadlines():
        sum_values = sum([int(s) for s in line.split()])
        print >> handle, record_count_2.next(), sum_values
    handle.close()


def get_seqs_by_id(fasta_file, names_file, out_file):
    """retrieves sequences from a large fasta file
    with matching fasta header"""
    names = [">" + l.strip().split()[0] for l in open(names_file)]
    fout = open(out_file, "w")
    print_line = False
    
    for line in open(fasta_file):
        line = line.strip()
        if line[0] == ">":
            if line in names:
                print_line = True
            else:
                print_line = False

        if print_line:
            fout.write(line)
            fout.write("\n")
    fout.close()
    

def get_reduced_seqs_by_id(fasta_file, names_file):
    """retrieves sequences based on fasta header
    then splits the sequences into a temporary folder"""
    fastadir = tempfile.mkdtemp()
    get_seqs_by_id(fasta_file, names_file, "all_reads.fasta")
    for record in SeqIO.parse(open("all_reads.fasta"), "fasta"):
            f_out = os.path.join(fastadir, record.id + '.fasta')
            SeqIO.write([record], open(f_out, "w"), "fasta")
    return fastadir
        
def format_blast_database(ref_file):
    cmd = ["formatdb",
           "-i", ref_file,
           "-p", "F"]
    subprocess.check_call(cmd)

def blast_against_reference(blast_in, combined, blast_type, outfile):
    cmd = ["blastall",
           "-p", "blastn",
           "-i", blast_in,
           "-d", combined,
           "-o", outfile,
           "-m", str(blast_type)]
    subprocess.check_call(cmd)

def blast_against_single(blast_in, ref, blast_type):
    cmd = ["blastall",
           "-p", "blastn",
           "-i", blast_in,
           "-d", ref,
           "-F", "f",
           "-e", "0.01",
           "-o", "blast_one.out",
           "-m", str(blast_type),
           "-a", "2"]
    subprocess.check_call(cmd)
    
def parse_blast_xml_report(blast_file, outfile):
    """uses biopython to split the output
    from a blast file with xml output"""
    result_handle = open(blast_file)
    blast_records = NCBIXML.parse(result_handle)
    blast_record = blast_records.next()    
    handle = open(outfile, "w") 
    for alignment in blast_record.alignments:
         for hsp in alignment.hsps:
             print >> handle, ">", alignment.title, hsp.sbjct
    handle.close()
    result_handle.close()

def filter_blast_report(blast_file, frag_length):
    """only return sequences that show a complete
    blast alignment with reference sequence"""
    # We will accept upto 99% of the frag_length belo
    min_frag_length = int(0.99 * frag_length)
    handle = open("continuous_seq_names.txt", "w")
    for line in open(blast_file):
        fields = line.split("\t")
        if int(fields[3]) >= min_frag_length:
            print >> handle, fields[0]
    handle.close()    

def parsed_blast_to_seqs(parsed_file, outfile):
    infile = open(parsed_file, "rU")
    handle = open(outfile, "w")
    for line in infile:
        fields = line.split(" ")
        print >> handle, fields[0] + fields[2], "\n", fields[3]
    handle.close()

def parse_hashrf_file(infile, outfile):
    handle = open(outfile, "a")
    for line in open(infile):
        if "<0,1>" in line:
            fields = line.split(" ")
            print >> handle, fields[1],
    handle.close()

def write_strip_name(filename, outfile):
    handle = open(outfile, "a")
    filename = os.path.splitext(os.path.basename(filename))[0]
    print >> handle, filename
    handle.close()

def paste_files(name_file, distance_file, all_distance_file):
    handle = open(all_distance_file, "w")
    output = []
    distance_file_lines = open(distance_file, "rU").readlines()

    for lines in zip(open(name_file, "rU"), open(distance_file, "rU")):
        handle.write("\t".join([s.strip() for s in lines]) + "\n")
    handle.close()

def filter_lines_by_value(filter_in, keep_length):
    handle = open("seq_names_over_value.txt", "w")
    for line in open(filter_in):
        fields = line.split(" ")
        if int(fields[1]) >= keep_length: 
            print >> handle, line,

def tree_loop(fastadir, combined, tree, parallel_workers):
    def _temp_name(t, f):
        return t + '_' + f
    
    def _perform_workflow(data):
        tn, f = data
        logging.debugPrint(lambda : "Processing file: %s" % f)
        blast_against_reference(f, combined, 7, _temp_name(tn, "blast.out"))
        parse_blast_xml_report(_temp_name(tn, "blast.out"), _temp_name(tn, "blast_parsed.txt"))
        subprocess.check_call("sort -u -k 3,3 %s > %s" % (_temp_name(tn, "blast_parsed.txt"),
                                                          _temp_name(tn, "blast_unique.parsed.txt")),
                              shell=True)
        parsed_blast_to_seqs(_temp_name(tn, "blast_unique.parsed.txt"), _temp_name(tn, "seqs_in.fas"))
        subprocess.check_call("muscle -in %s -out %s > /dev/null 2>&1" % (_temp_name(tn, "seqs_in.fas"),
                                                                          _temp_name(tn, "seqs_aligned.fas")),
                              shell=True)
        subprocess.check_call("FastTree -nt -noboot %s > %s 2> /dev/null" % (_temp_name(tn, "seqs_aligned.fas"),
                                                                             _temp_name(tn, "tmp.tree")),
                              shell=True)
        subprocess.check_call("cat %s %s > %s" % (_temp_name(tn, "tmp.tree"),
                                                  tree,
                                                  _temp_name(tn, "combined.tree")),
                              shell=True)
        # hashrf doesn't return 0 on success unfortunately
        subprocess.call("hashrf %s 2 -p list -o %s > /dev/null 2>&1" % (_temp_name(tn, "combined.tree"),
                                                                        _temp_name(tn, "result.rf")),
                        shell=True)

        thread_id = id(threading.current_thread())
        thread_distance_file = str(thread_id) + '_distance.txt'
        parse_hashrf_file(_temp_name(tn, "result.rf"), thread_distance_file)
        thread_name_file = str(thread_id) + '_name.txt'
        write_strip_name(f, thread_name_file)
        subprocess.check_call(["rm",
                              _temp_name(tn, "blast.out"),
                              _temp_name(tn, "blast_parsed.txt"),
                              _temp_name(tn, "blast_unique.parsed.txt"),
                              _temp_name(tn, "seqs_in.fas"),
                              _temp_name(tn, "seqs_aligned.fas"),
                              _temp_name(tn, "tmp.tree"),
                              _temp_name(tn, "combined.tree"),
                              _temp_name(tn, "result.rf")])
        return (thread_distance_file, thread_name_file)

    files = os.listdir(fastadir)
    files_and_temp_names = [(str(idx), os.path.join(fastadir, f))
                            for idx, f in enumerate(files)]

    results = set(p_func.pmap(_perform_workflow,
                              files_and_temp_names,
                              num_workers=parallel_workers))

    # Ignore failure if these don't exist
    subprocess.call(["rm", "distance.txt", "name.txt"])
    for files in func.chunk(5, results):
        distances = [d for d, _ in files]
        names = [n for _, n in files]
        subprocess.check_call("cat %s >> distance.txt" % " ".join(distances), shell=True)
        subprocess.check_call("cat %s >> name.txt" % " ".join(names), shell=True)
        subprocess.check_call("rm %s" % " ".join(distances), shell=True)
        subprocess.check_call("rm %s" % " ".join(names), shell=True)
    paste_files("name.txt", "distance.txt", "all_distances.txt")

def cleanup_tmpdirs(fastadir):
    subprocess.check_call(["rm", "-rf", fastadir])

def pull_line(names_in, quality_in, out_file):
    handle = open(out_file, "w")
    counts = open(quality_in)
    names = [l.rstrip("\n") for l in open(names_in)]
    for line in counts:
        fields = line.strip().split("\t")
        if fields[0] in names:
            print >> handle, line,

def merge_files_by_column(column, file_1, file_2, out_file):
    """Takes 2 file and merge their columns based on the column. It is assumed
    that line ordering in the files do not match, so we read both files into memory
    and join them"""
    join_map = {}
    for line in open(file_1):
        row = line.split()
        column_value = row.pop(column)
        join_map[column_value] = row

    for line in open(file_2):
        row = line.split()
        column_value = row.pop(column)
        if column_value in join_map:
            join_map[column_value].extend(row)

    fout = open(out_file, 'w')
    for k, v in join_map.iteritems():
        fout.write('\t'.join([k] + v) + '\n')

    fout.close()
        
def main(alignment, mask, ref, combined, tree, step_size, frag_length, keep_length, parallel_workers):
    reads = split_sequence_by_window(alignment, step_size, frag_length) 
    ####split fasta reads into chunks of a specified size
    write_sequences(reads)
    qual_reads = split_quality_values(mask, step_size, frag_length)
    write_qualities(qual_reads)
    ####do the same thing for the quality file out of mothur
    split_read("quals_shredded.txt")
    ####pads quality file with spaces
    sum_qual_reads("padded_quals.txt")
    ####adds quality values from array
    filter_lines_by_value("summed_qualities.txt", keep_length)
    get_seqs_by_id("seqs_shredded.txt", "seq_names_over_value.txt", "query_sequences.fas")
    ####retrieves sequences from shredded file if they contain the same FASTA header
    format_blast_database(ref)
    logging.logPrint("Blasting to find contiguous sequences")
    blast_against_single("query_sequences.fas", ref, 8)
    filter_blast_report("blast_one.out", frag_length)
    format_blast_database(combined)
    fastadir = get_reduced_seqs_by_id("query_sequences.fas", "continuous_seq_names.txt") 
    logging.logPrint("Starting the loop")
    tree_loop(fastadir, combined, tree, parallel_workers)
    logging.logPrint("Loop finished")
    subprocess.check_call("awk '{print $1}' all_distances.txt > names.txt", shell=True) #should I sort?
    pull_line("names.txt", "summed_qualities.txt", "reduced_quals.txt")
    merge_files_by_column(0, "all_distances.txt", "summed_qualities.txt", "results.txt")
    logging.logPrint("Cleaning up")
    #subprocess.check_call("rm quals_shredded.txt padded_quals.txt blast* continuous* distance.txt *.log name.txt seq_names_over_value.txt", shell=True)
    cleanup_tmpdirs(fastadir)

if __name__ == "__main__":
    usage="usage: %prog [options]"
    parser = optparse.OptionParser(usage=usage)
    parser.add_option("-a", "--alignment", dest="alignment",
                      help="/path/to/alignment [REQUIRED]",
                      action="store", type="string")
    parser.add_option("-m", "--mask", dest="mask",
                      help="/path/to/filter_mask [REQUIRED]",
                      action="store", type="string")
    parser.add_option("-r", "--ref_file", dest="ref",
                      help="/path/to/reference_genome [REQUIRED]",
                      action="store", type="string")
    parser.add_option("-c", "--combined_seqs", dest="combined",
                      help="/path/to/multifasta_references [REQUIRED]",
                      action="store", type="string")
    parser.add_option("-t", "--tree", dest="tree",
                      help="/path/to/reference_tree [REQUIRED]",
                      action="store", type="string")
    parser.add_option("-s", "--step", dest="step_size",
                      help="step size for shredding sequences",
                      default="5", type="int")
    parser.add_option("-l", "--frag_length", dest="frag_length",
                      help="shred sequences into given length",
                      default="500", type="int")
    parser.add_option("-k", "--keep_length", dest="keep_length",
                      help="keep if polymorphisms greater than value",
                      default="50", type="int")
    parser.add_option("", "--parallel_workers", dest="parallel_workers",
                      help="How much work to do in parallel, defaults to 2, should number of CPUs your machine has",
                      default="2", type="int")
    parser.add_option("", "--debug", dest="debug",
                      help="Turn debug statements on",
                      action="store_true", default=False)
    
    options, args = parser.parse_args()
    
    mandatories = ["alignment", "mask", "ref", "combined", "tree"]
    for m in mandatories:
        if not getattr(options, m, None):
            print "\nMust provide %s.\n" %m
            parser.print_help()
            exit(-1)

    logging.DEBUG = options.debug
            
    main(options.alignment, options.mask, options.ref, options.combined, options.tree, options.step_size, 
         options.frag_length, options.keep_length, options.parallel_workers)

