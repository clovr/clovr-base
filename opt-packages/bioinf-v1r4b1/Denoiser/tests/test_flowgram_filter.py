#!/usr/bin/env python
"""Tests for filtering of flowgram file"""

from os import remove

from cogent.util.unit_test import TestCase, main
from cogent.parse.fasta import MinimalFastaParser
from cogent.parse.flowgram_collection import FlowgramCollection
from cogent.parse.flowgram import Flowgram
from cogent.app.util import get_tmp_filename

from Denoiser.Flowgram_filter import extract_barcodes_from_mapping, build_inverse_barcode_map, writeSFFHeader, filterSFFFile, withinLength
from Denoiser.settings import PROJECT_HOME

class Test_flowgram_filter(TestCase):
   def setUp(self):
       self.test_map = {'1': ('a','b','c'),
                        '2': ('d','e','f')}
       self.labels = ['Uneven1_1 FV9NWLF01EVGI8 orig_bc=TCGAGCGAATCT new_bc=TCGAGCGAATCT bc_diffs=0',
                      'Even1_2 FV9NWLF01DROG9 orig_bc=TAGTTGCGAGTC new_bc=TAGTTGCGAGTC bc_diffs=0',
                      'Uneven1_3 FV9NWLF01DZTVJ orig_bc=TCGAGCGAATCT new_bc=TCGAGCGAATCT bc_diffs=0',
                      'Uneven3_4 FV9NWLF01DI8SC orig_bc=TCTGCTAGATGT new_bc=TCTGCTAGATGT bc_diffs=0',
                      'Even3_5 FV9NWLF01DW381 orig_bc=TCATCGCGATAT new_bc=TCATCGCGATAT bc_diffs=0',
                      'Even3_6 FV9NWLF01DP96S orig_bc=TCATCGCGATAT new_bc=TCATCGCGATAT bc_diffs=0',
                      'Uneven2_7 FV9NWLF01BOY7E orig_bc=TCGTTCACATGA new_bc=TCGTTCACATGA bc_diffs=0',
                      'Even1_8 FV9NWLF01A0OG1 orig_bc=TAGTTGCGAGTC new_bc=TAGTTGCGAGTC bc_diffs=0',
                      'Even2_9 FV9NWLF01DJZFF orig_bc=TCACGATTAGCG new_bc=TCACGATTAGCG bc_diffs=0',
                      'Uneven1_10 FV9NWLF01D4LTB orig_bc=TCGAGCGAATCT new_bc=TCGAGCGAATCT bc_diffs=0']

   def test_writeSFFHeader(self):
      
      expected = """Common Header:
  Magic Number:\t0x2E736666
  Version:\t0001
  Index Offset:\t7773224
  Index Length:\t93365
  # of Reads:\t114
  Header Length:\t440
  Key Length:\t4
  # of Flows:\t400
  Flowgram Code:\t1
  Flow Chars:\tTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACG
  Key Sequence:\tTCAG
""".split('\n')
      header = {'Version':"0001",
                'Magic Number': '0x2E736666',
                'Index Offset':  '7773224',
                'Index Length':  '93365',
                '# of Reads':    '114',
                'Header Length': '440',
                'Key Length':    '4',
                '# of Flows':    '400',
                'Flowgram Code': '1',
                'Flow Chars':    'TACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACGTACG',
                'Key Sequence':  'TCAG'}

      tmp_name = get_tmp_filename(prefix="test_writeSFFHeader")
      fh = open(tmp_name,"w")
      writeSFFHeader(header, fh, num=400)
      fh.close()
      fh = open(tmp_name,"U")
      lines =list(fh)
      remove(tmp_name)
      self.assertEqualItems(lines, map(lambda a: a +"\n", expected))

   def test_filterSFFFile(self):
      """filterSFFFile filters out bad reads."""

      try:
         fh = open(PROJECT_HOME+"/tests/TestData/tiny_test.sff.txt")
      except IOError:
         self.fail("Could not open test file TestData/tiny_test.sff.txt. Skipping test")
   
      #With no filters all flowgram should be in out file
      filter_list = []
      out_file_name = get_tmp_filename(prefix="test_filterSFFFile", suffix=".sff.txt")
      out_fh = open(out_file_name,"w")
      l = filterSFFFile(fh, filter_list, out_fh) 
      remove(out_file_name)
      fh.close()
      self.assertEqual(l, 114)
      
      #With good filters some should survive
      fh = open(PROJECT_HOME+"/tests/TestData/tiny_test.sff.txt")
      filter_list = [lambda f:withinLength(f,100,300)]
      out_file_name = get_tmp_filename(prefix="test_filterSFFFile", suffix=".sff.txt")
      out_fh = open(out_file_name,"w")
      l = filterSFFFile(fh, filter_list, out_fh) 
      remove(out_file_name)
      fh.close()
      self.assertEqual(l, 112)

      #With strong filters nothing should be in 
      fh = open(PROJECT_HOME+"/tests/TestData/tiny_test.sff.txt")
      filter_list = [lambda f:withinLength(f,0,0)]
      out_file_name = get_tmp_filename(prefix="test_filterSFFFile", suffix=".sff.txt")
      out_fh = open(out_file_name,"w")
      l = filterSFFFile(fh, filter_list, out_fh) 
      remove(out_file_name)
      self.assertEqual(l, 0)

   def test_withinLength(self):
      """"withinLength checks whether a flowgram is within a lenth."""

      flow1 = Flowgram("0 1.2 2.1 3.4 0.02 0.01 1.02 0.08") # len 7
      flow2 = Flowgram('0.5 1.0 4.1 0.0 0.0 1.23 0.0 3.1')  # len 10

      self.assertTrue(withinLength(flow1, 0,10))
      self.assertFalse(withinLength(flow1, 10,20))
      self.assertFalse(withinLength(flow2, 0,5))
      self.assertTrue(withinLength(flow2, 5,20))
      self.assertTrue(withinLength(flow2, 5,11))

   def test_truncate_flowgrams_in_SFF(self):
      pass

   def test_cleanup_sff(self):
      pass
      
   def test_split_sff(self):
      pass

   def test_build_inverse_barcode_map(self):
       """build_inverse_barcode_map maps flow ids to sample ids."""

       expected = ({'FV9NWLF01EVGI8':'Uneven1',
                    'FV9NWLF01DROG9':'Even1',
                    'FV9NWLF01DZTVJ':'Uneven1',
                    'FV9NWLF01DI8SC':'Uneven3',
                    'FV9NWLF01DW381':'Even3',
                    'FV9NWLF01DP96S':'Even3',
                    'FV9NWLF01BOY7E':'Uneven2',
                    'FV9NWLF01A0OG1':'Even1',
                    'FV9NWLF01DJZFF':'Even2',
                    'FV9NWLF01D4LTB':'Uneven1'},
                   {'Even1':2,
                    'Even2':1,
                    'Even3':2,
                    'Uneven1':3,
                    'Uneven2':1,
                    'Uneven3':1})
       dummy_fasta = [(a,"") for a in self.labels]             
       observed = build_inverse_barcode_map(dummy_fasta)
       self.assertEqual(observed, expected)

   def test_extract_barcodes_from_mapping(self):
       """extract_barcodes_from_mapping pulls out the barcodes and ids."""
       
       expected = {'FV9NWLF01EVGI8':'TCGAGCGAATCT',
                   'FV9NWLF01DROG9':'TAGTTGCGAGTC',
                   'FV9NWLF01DZTVJ':'TCGAGCGAATCT',
                   'FV9NWLF01DI8SC':'TCTGCTAGATGT',
                   'FV9NWLF01DW381':'TCATCGCGATAT',
                   'FV9NWLF01DP96S':'TCATCGCGATAT',
                   'FV9NWLF01BOY7E':'TCGTTCACATGA',
                   'FV9NWLF01A0OG1':'TAGTTGCGAGTC',
                   'FV9NWLF01DJZFF':'TCACGATTAGCG',
                   'FV9NWLF01D4LTB':'TCGAGCGAATCT'}

       obs = extract_barcodes_from_mapping(self.labels)
       self.assertEqual(obs, expected)

if __name__ == "__main__":
    main()
