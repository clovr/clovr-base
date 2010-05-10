#!/usr/local/projects/dacc/sra/qiime/external/python/bin/python
# File created on 09 Feb 2010
from __future__ import division

__author__ = "Greg Caporaso"
__copyright__ = "Copyright 2010, The QIIME project"
__credits__ = ["Greg Caporaso"]
__license__ = "GPL"
__version__ = "1.0.0-dev"
__maintainer__ = "Greg Caporaso"
__email__ = "gregcaporaso@gmail.com"
__status__ = "Development"

from qiime.util import parse_command_line_parameters
from optparse import make_option
from optparse import OptionParser
from glob import glob
from os import popen, makedirs
from os.path import split, splitext, join
from subprocess import check_call, CalledProcessError
from cogent.app.util import get_tmp_filename
from qiime.parallel.util import get_random_job_prefix, write_jobs_file,\
    submit_jobs, get_poller_command, get_rename_command,\
    write_filepaths_to_file
from qiime.beta_diversity import list_known_metrics
from qiime.util import load_qiime_config, get_qiime_scripts_dir, get_options_lookup
from qiime.parallel.beta_diversity import get_job_commands

qiime_config = load_qiime_config()
options_lookup = get_options_lookup()

script_info={}
script_info['brief_description']="""Parallel beta diversity"""
script_info['script_description']="""This script performs like the beta_diversity.py script, but is intended to make use of multicore/multiprocessor environments to perform analyses in parallel."""
script_info['script_usage']=[]
script_info['script_usage'].append(("""Example""","""Apply the dist_unweighted_unifrac and the dist_weighted_unifrac metrics (-m) to all otu tables in /home/qiime_user/rare/ (-i) and write the resulting output files to /home/qiime_user/out/ (-o, will be created if it doesn't exist). Use the tree file /home/qiime_user/rep_set.tre (-t) when necessary.""","""%prog -i /home/qiime_user/rare/ -o /home/qiime_user/out -m dist_unweighted_unifrac,dist_weighted_unifrac -t /home/qiime_user/rep_set.tre"""))

script_info['output_description']="""The output of %prog is a folder containing text files, each a distance matrix between samples."""

script_info['required_options'] = [\
 make_option('-i', '--input_path',
        help='input path, must be directory [REQUIRED]'),\
 make_option('-o', '--output_path',
        help='output path, must be directory [REQUIRED]'),\
 make_option('-m', '--metrics',
        help='metrics to use [REQUIRED]')
]

script_info['optional_options'] = [\
 make_option('-t', '--tree_path',
        help='path to newick tree file, required for phylogenetic metrics'+\
        ' [default: %default]'),\
 make_option('-N','--beta_diversity_fp',action='store',\
           type='string',help='full path to '+\
           'scripts/beta_diversity.py [default: %default]',\
           default=join(get_qiime_scripts_dir(),'beta_diversity.py')),\
 options_lookup['poller_fp'],\
 options_lookup['retain_temp_files'],\
 options_lookup['suppress_submit_jobs'],\
 options_lookup['poll_directly'],\
 options_lookup['cluster_jobs_fp'],\
 options_lookup['suppress_polling'],\
 options_lookup['job_prefix'],\
 options_lookup['python_exe_fp'],\
 options_lookup['seconds_to_sleep']\
]
script_info['version'] = __version__

def main():
    option_parser, opts, args = parse_command_line_parameters(**script_info)
    
    # create local copies of command-line options
    input_dir = opts.input_path
    output_dir = opts.output_path
    metrics = opts.metrics
    tree_fp = opts.tree_path
    
    beta_diversity_fp = opts.beta_diversity_fp
    python_exe_fp = opts.python_exe_fp
    path_to_cluster_jobs = opts.cluster_jobs_fp
    poller_fp = opts.poller_fp
    retain_temp_files = opts.retain_temp_files
    suppress_polling = opts.suppress_polling
    seconds_to_sleep = opts.seconds_to_sleep
    poll_directly = opts.poll_directly

    created_temp_paths = []
    input_fps = glob('%s/*' % input_dir)
    # split the input filepath into directory and filename, base filename and
    # extension
    # input_dir, input_fn = split(input_path)
    # input_file_basename, input_file_ext = splitext(input_fn)
    
    # set the job_prefix either based on what the user passed in,
    # or a random string beginning with ALDIV (ALphaDIVersity)
    job_prefix = opts.job_prefix or get_random_job_prefix('BDIV')
    
    # A temporary output directory is created in output_dir named
    # job_prefix. Output files are then moved from the temporary 
    # directory to the output directory when they are complete, allowing
    # a poller to detect when runs complete by the presence of their
    # output files.
    working_dir = '%s/%s' % (output_dir,job_prefix)
    try:
        makedirs(working_dir)
        created_temp_paths.append(working_dir)
    except OSError:
        # working dir already exists
        pass
    
    # build the filepath for the 'jobs script'
    jobs_fp = '%s/%sjobs.txt' % (output_dir, job_prefix)
    created_temp_paths.append(jobs_fp)
    
    # Get the list of commands to be run and the expected result files
    commands, job_result_filepaths  = \
     get_job_commands(python_exe_fp,beta_diversity_fp,tree_fp,job_prefix,\
     metrics,input_fps,output_dir,working_dir)
    
    # Set up poller apparatus if the user does not suppress polling
    if not suppress_polling:
        # Write the list of files which must exist for the jobs to be 
        # considered complete
        expected_files_filepath = '%s/expected_out_files.txt' % working_dir
        write_filepaths_to_file(job_result_filepaths,expected_files_filepath)
        created_temp_paths.append(expected_files_filepath)
        
        # Write the mapping file which described how the output files from
        # each job should be merged into the final output files
        merge_map_filepath = '%s/merge_map.txt' % working_dir
        open(merge_map_filepath,'w').close()
        created_temp_paths.append(merge_map_filepath)
        
        # Create the filepath listing the temporary files to be deleted,
        # but don't write it yet
        deletion_list_filepath = '%s/deletion_list.txt' % working_dir
        created_temp_paths.append(deletion_list_filepath)

        if not poll_directly:
            # Generate the command to run the poller, and the list of temp files
            # created by the poller
            poller_command, poller_result_filepaths =\
             get_poller_command(python_exe_fp,poller_fp,expected_files_filepath,\
             merge_map_filepath,deletion_list_filepath,\
             seconds_to_sleep=seconds_to_sleep)
            # append the poller command to the list of job commands
            commands.append(poller_command)
        else:
            poller_command, poller_result_filepaths =\
             get_poller_command(python_exe_fp,poller_fp,expected_files_filepath,\
             merge_map_filepath,deletion_list_filepath,\
             seconds_to_sleep=seconds_to_sleep,\
             command_prefix='',command_suffix='')            
        created_temp_paths += poller_result_filepaths
        
        if not retain_temp_files:
            # If the user wants temp files deleted, now write the list of 
            # temp files to be deleted
            write_filepaths_to_file(created_temp_paths,deletion_list_filepath)
        else:
            # Otherwise just write an empty file
            write_filepaths_to_file([],deletion_list_filepath)
    
    # write the commands to the 'jobs files'
    write_jobs_file(commands,job_prefix=job_prefix,jobs_fp=jobs_fp)
    
    # submit the jobs file using cluster_jobs, if not suppressed by the
    # user
    if not opts.suppress_submit_jobs:
        submit_jobs(path_to_cluster_jobs,jobs_fp,job_prefix)
        
    if poll_directly:
        try:
            check_call(poller_command.split())
        except CalledProcessError, e:
            print '**Error occuring when calling the poller directly. '+\
            'Jobs may have been submitted, but are not being polled.'
            print str(e)
            exit(-1)


if __name__ == "__main__":
    main()