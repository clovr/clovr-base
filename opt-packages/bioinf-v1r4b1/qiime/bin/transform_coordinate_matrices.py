#!/usr/bin/python
# File created on 21 Feb 2010
from __future__ import division

__author__ = "Greg Caporaso"
__copyright__ = "Copyright 2010, The QIIME project"
__credits__ = ["Greg Caporaso"]
__license__ = "GPL"
__version__ = "1.1.0-dev"
__maintainer__ = "Greg Caporaso"
__email__ = "gregcaporaso@gmail.com"
__status__ = "Development"

from optparse import make_option
from os.path import split, splitext, exists
from os import makedirs
from qiime.util import parse_command_line_parameters
from qiime.parse import fields_to_dict
from qiime.transform_coordinate_matrices import procrustes_monte_carlo,\
    get_procrustes_results

script_info={}
script_info['brief_description']="""Transform 2 coordinate matrices"""
script_info['script_description']="""This script transformms 2 coordinate matrices (e.g., the output of principal_coordinates.py) using procrustes analysis to minimize the distances between corresponding points. Monte Carlo simulations can additionally be performed (-r random trials are run) to estimate the probability of seeing an M^2 value as extreme as the actual M^2."""
script_info['script_usage']=[]
script_info['script_usage'].append(("Generate monte carlo p-values","","""%prog -r 1000 -i weighted_unifrac_coords.txt,unweighted_unifrac_coords.txt""",))
  
script_info['script_usage'].append(("Write the transformed procrustes matrices to file","","""%prog -o out/ -i weighted_unifrac_coords.txt,unweighted_unifrac_coords.txt"""))

script_info['output_description']="""Two transformed coordinate matrices corresponding to the two input coordinate matrices, and (if -r was specified) a text file summarizing the results of the Monte Carlo simulations."""
script_info['required_options']=[\
 make_option('-i','--input_fps',help='comma-separated input files'),\
 make_option('-o','--output_dir',help='the output directory'),\
]
script_info['optional_options']=[\
 make_option('-r','--random_trials',type='int',\
    help='Number of random permutations of matrix2 to perform. '+\
    ' [default: (no Monte Carlo analysis performed)]',default=None),\
 make_option('-d','--num_dimensions',type='int',\
    help='Number of dimensions to include in output matrices'+\
    ' [default: Consider all dimensions]',default=None),\
 make_option('-s','--sample_id_map_fp',\
    help='Map of original sample ids to new sample ids [default: %default]',\
    default=None),\
]

script_info['version'] = __version__



def main():
    option_parser, opts, args = parse_command_line_parameters(**script_info)

    random_trials = opts.random_trials
    output_dir = opts.output_dir
    sample_id_map_fp = opts.sample_id_map_fp
    num_dimensions = opts.num_dimensions
    
    if not exists(output_dir): 
        makedirs(output_dir)
    
    input_fps = opts.input_fps.split(',')
    input_fp1 = input_fps[0]
    input_fp2 = input_fps[1]
    input_fp1_dir, input_fn1 = split(input_fp1)
    input_fp1_basename, input_fp1_ext = splitext(input_fn1)
    input_fp2_dir, input_fn2 = split(input_fp2)
    input_fp2_basename, input_fp2_ext = splitext(input_fn2)
    output_summary_fp = '%s/%s_%s_procrustes_results.txt' %\
     (output_dir,input_fp1_basename,input_fp2_basename)
    output_matrix1_fp = '%s/pc1_transformed.txt' % output_dir
    output_matrix2_fp = '%s/pc2_transformed.txt' % output_dir
    
    if sample_id_map_fp:
        sample_id_map = dict([(k,v[0]) \
         for k,v in fields_to_dict(open(sample_id_map_fp)).items()])
    else:
        sample_id_map = None
    
    transformed_coords1, transformed_coords2, m_squared =\
      get_procrustes_results(open(input_fp1,'U'),\
                             open(input_fp2,'U'),\
                             sample_id_map=sample_id_map,\
                             randomize=False,
                             max_dimensions=num_dimensions)
    output_matrix1_f = open(output_matrix1_fp,'w')
    output_matrix1_f.write(transformed_coords1)
    output_matrix1_f.close()
    output_matrix2_f = open(output_matrix2_fp,'w')
    output_matrix2_f.write(transformed_coords2)
    output_matrix2_f.close()
    
    if random_trials:
        summary_file_lines = ['FP1 FP2 Included_dimensions MC_p_value M^2']
        coords_f1 = list(open(input_fp1,'U'))
        coords_f2 = list(open(input_fp2,'U'))
        for max_dims in [3,5,10,15,20,None]:
            actual_m_squared, trial_m_squareds, count_better, mc_p_value =\
             procrustes_monte_carlo(coords_f1,\
                                    coords_f2,\
                                    trials=random_trials,\
                                    max_dimensions=max_dims,\
                                    sample_id_map=sample_id_map)
            summary_file_lines.append('%s %s %s %1.5f %d %1.3f' %\
             (input_fp1, input_fp2, str(max_dims), mc_p_value,\
              count_better, actual_m_squared))
        f = open(output_summary_fp,'w')
        f.write('\n'.join(summary_file_lines))
        f.close()


if __name__ == "__main__":
    main()