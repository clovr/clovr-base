#!/usr/local/projects/dacc/sra/qiime/external/python/bin/python
# File created on 09 Feb 2010
from __future__ import division

__author__ = "Doug Wendel"
__copyright__ = "Copyright 2010, The QIIME project"
__credits__ = ["Catherine Lozupone", "Jesse Stombaugh", "Doug Wendel"]
__license__ = "GPL"
__version__ = "1.0.0-dev"
__maintainer__ = "Doug Wendel"
__email__ = "wendel@colorado.edu"
__status__ = "Development"
 

from qiime.otu_category_significance import test_wrapper
from qiime.util import parse_command_line_parameters
from optparse import make_option

script_info={}
script_info['brief_description']="""OTU significance and co-occurence analysis"""
script_info['script_description']="""The script otu_category_significance.py tests whether any of the OTUs in an OTU table are significantly associated with a category in the category mapping file. This code uses, ANOVA, the G test of independence, or Pearson correlation to find OTUs whose members are differentially represented across experimental treatments or measured variables. It can also be used with presence/absence or abundance data for a phylogenetic group (such as that determined with quantitative PCR) to determine if any OTUs co-occur with a taxon of interest."""
script_info['script_usage']=[]
script_info['script_usage'].append(("Example 1","""If the user would like to perform a G test on their OTU table using default parameters, while testing the category "Sex", they can run the following command:""","""otu_category_significance.py -i otu_table.txt -m Mapping_file.txt -s g_test -c Sex"""))
script_info['script_usage'].append(("Example 2","""If the user would like to perform the same test using numerical qPCR data, where everything below a threshold value should be considered "absent" and everything above that value "present", the user will need to set the threshold by running the following command:""","""otu_category_significance.py -i otu_table.txt -m Mapping_file.txt -s g_test -c qPCR -t 0.16"""))
script_info['script_usage'].append(("Example 3","""Alternatively, the user could run an ANOVA test on the same data by using the following command:""","""otu_category_significance.py -i otu_table.txt -m Mapping_file.txt -s ANOVA -c Sex"""))
script_info['output_description']="""The G test results are output as tab delimited text, which can be examined in Excel. The output has the following columns:

* OTU: The name of the OTU.
* g_val: The raw test statistic.
* g_prob: The probability that this OTU is non-randomly distributed across the categories.
* Bonferroni_corrected: The probability after correction for multiple comparisons with the Bonferroni correction. In this correction, the p-value is multiplied by the number of comparisons performed (the number of OTUs remaining after applying the filter).
* FDR_corrected: The probability after correction with the "false discovery rate" method. In this method, the raw p-values are ranked from low to high. Each p-value is multiplied by the number of comparisons divided by the rank. This correction is less conservative than the Bonferroni correction. The list of significant OTUs is expected to have the percent of false positives predicted by the p value.
* Contingency table columns: The next columns give the information in the contingency table and will vary in number and name based on the number of categories and their names. The two numbers in brackets represent the number of samples that were observed in those categories and the number that would be expected if the OTU members were randomly distributed across samples in the different categories. These columns can be used to evaluate the nature of a non-random association (e.g. if that OTU is always present in a particular category or if it is never present).
* Consensus lineage: The consensus lineage for that OTU will be listed in the last column if it was present in the input OTU table.

The ANOVA results are output as tab delimited text that can be examined in Excel. The output has the following columns:

* OTU: The name of the OTU.
* prob: The raw probability from the ANOVA 
* Bonferroni_corrected: The probability after correction for multiple comparisons with the Bonferroni correction. In this correction, the p-value is multiplied by the number of comparisons performed (the number of OTUs remaining after applying the filter). 
* FDR_corrected: The probability after correction with the "false discovery rate" method. In this method, the raw p-values are ranked from low to high. Each p-value is multiplied by the number of comparisons divided by the rank. This correction is less conservative than the Bonferroni correction. The list of significant OTUs is expected to have the percent of false positives predicted by the p value.
* Category Mean Columns: Contains one column for each category reporting the mean count of the OTU in that category.
* Consensus lineage: The consensus lineage for that OTU will be listed in the last column if it was present in the input OTU table.

The correlation test results are output as tab delimited text, which can be examined in Excel. The output has the following columns:

* OTU: The name of the OTU.  
* prob: The probability that the OTU relative abundance is correlated with the category values across samples. 
* Bonferroni_corrected: The probability after correction for multiple comparisons with the Bonferroni correction. In this correction, the p-value is multiplied by the number of comparisons performed (the number of OTUs remaining after applying the filter). 
* FDR_corrected: The probability after correction with the "false discovery rate" method. In this method, the raw p-values are ranked from low to high. Each p-value is multiplied by the number of comparisons divided by the rank. This correction is less conservative than the Bonferroni correction. The list of significant OTUs is expected to have the percent of false positives predicted by the p value.
* r: Pearson's r. This value ranges from -1 to +1, with -1 indicating a perfect negative correlation, +1 indicating a perfect positive correlation, and 0 indicating no relationship.
* Consensus lineage: The consensus lineage for that OTU will be listed in the last column if it was present in the input OTU table.
"""

script_info['required_options']=[\
    make_option('-i','--otu_table_fp', dest='otu_table_fp',\
        help='path to the otu table'),\
    make_option('-m','--category_mapping_fp',\
        dest='category_mapping_fp',\
        help='path to category mapping file'),\
    make_option('-c','--category', dest='category',\
        help='name of category over which to run the analysis')
]

script_info['optional_options']=[\
    make_option('-s','--test', dest='test', default='g_test',\
        help='the type of statistical test to run. options are: ' +\
        'g_test: determines whether OTU presence/absence is associated ' +\
        'with a category using the G test of independence. ' +\
        'ANOVA: determines whether OTU abundance is associated with a ' +\
        'category. ' +\
        'correlation: determines whether OTU abundance is correlated ' +\
        'with a continuous variable in the category mapping file.'),\
    make_option('-o','--output_fp', dest='output_fp', \
        default= 'otu_category_significance_results.txt',\
        help='path to output file. otu_category_significance_results.txt by default'),\
    make_option('-f','--filter', dest='filter',\
        default= 10, \
        help='minimum number of samples that must contain the OTU for the ' +\
        'OTU to be included in the analysis. default value=10.'),\
    make_option('-t','--threshold', dest='threshold', default=None, \
        help='threshold under which to consider something absent: ' +\
        'Only used if you have numerical data that should be converted to ' +\
        'present or absent based on a threshold. Should be None for ' +\
        'categorical data or with the correlation test. default value is None'),\
    make_option('-l', '--otu_include_fp', dest='otu_include_fp', default=None,\
        help='path to a file with a list of OTUs to evaluate. By default ' +\
        'evaluates all OTUs that pass the minimum sample filter. If a ' +\
        'filepath is given here in which each OTU name one wishes to ' +\
        'evaluate is on a separate line, will apply this additional filter')
]
script_info['version'] = __version__

def main():
    option_parser, opts, args = parse_command_line_parameters(**script_info)

    verbose = opts.verbose

    otu_table_fp = opts.otu_table_fp
    otu_table = open(otu_table_fp,'U')
    output_fp = opts.output_fp

    category_mapping_fp = opts.category_mapping_fp
    category_mapping = open(category_mapping_fp,'U')

    filter = opts.filter
    category = opts.category
    threshold = opts.threshold
    if threshold and threshold != 'None':
        threshold = float(threshold)
    test = opts.test

    otu_include_fp = opts.otu_include_fp
    if otu_include_fp and otu_include_fp != 'None':
        otu_include = open(otu_include_fp)
    else:
        otu_include = None

    output = test_wrapper(test, otu_table, category_mapping, category, \
                threshold, filter, output_fp, otu_include)
    of = open(output_fp, 'w')
    of.write('\n'.join(output))
    of.close()

if __name__ == "__main__":
    main()
