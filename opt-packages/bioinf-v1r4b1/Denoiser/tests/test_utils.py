#!/usr/bin/env python
"""Tests for function in utils."""

from os import remove, rmdir
from os.path import exists
from cogent.util.unit_test import TestCase, main
from cogent.parse.fasta import MinimalFastaParser
from cogent.parse.flowgram import Flowgram
from cogent import Sequence
from cogent.app.util import ApplicationNotFoundError
from cogent.util.misc import remove_files
from cogent.app.util import get_tmp_filename

from Denoiser.utils import make_stats, get_representatives,\
    squeeze_seq, waitForFile, waitForClusterIds,\
    initFlowgramFile, appendToFlowgramFile, store_mapping,\
    store_clusters, invert_mapping, create_dir
from Denoiser.settings import PROJECT_HOME

class TestUtils(TestCase):
   def setUp(self):
        self.data = dict({"0": "ab", "1":"abababa", "2":"abab",
                          "3":"baba", "4":"ababaa","5":"a", "6":"abababa",
                          "7":"bab", "8":"babba"})
        self.mapping = {"1":["0","2","5","6"],
                        "3":[],
                        "4":[],
                        "8":["7"]}
        self.test_map = {'1': ('a','b','c'),
                         '2': ('d','e','f')}

        #set up test file
        open("/tmp/denoiser_utils_dummy.tmp","w")
        self.files_to_remove=["/tmp/denoiser_utils_dummy.tmp"]
        self.tmpdir=""
        
   def tearDown(self):
      """Clean up tmp files."""
      remove_files(self.files_to_remove, False)
      if self.tmpdir:
         rmdir(self.tmpdir)
      #clean up the file from initFlowgramFile
      if (hasattr(self,"tmp_filename") and exists(self.tmp_filename)):
         remove(self.tmp_filename)
         
   def test_invert_mapping(self):
      """invert_prefix_map inverts a dictionary mapping."""
      
      actual = invert_mapping(self.test_map)
      self.assertEqual({'1':'1','a':'1', 'b':'1', 'c':'1','2':'2','d':'2','e':'2','f':'2'}, actual)
      
   def test_make_stats(self):
      """make_stats produces meaningful statistics."""
      map = self.mapping
      stats = """Clustersize\t#
1:\t\t2
2:\t\t1
5:\t\t1""" 
       
      self.assertEqual(make_stats(map), stats)

   def test_store_mapping(self):
      """store_mapping writes mapping to file."""

      expected = ["1:\t0\t2\t5\t6\n",
                  "3:\n",
                  "4:\n",
                  "8:\t7\n"]

      self.files_to_remove.append("/tmp/test_store_mapping_mapping.txt")      
      store_mapping(self.mapping,"/tmp/", prefix="test_store_mapping")
      observed = list(open("/tmp/test_store_mapping_mapping.txt","U"))      
      self.assertEqualItems(observed, expected)

   def test_store_cluster(self):
        """store_clusters stores the centroid seqs for each cluster."""

        self.tmpdir = get_tmp_filename(tmp_dir="/tmp/", suffix="/")
        create_dir(self.tmpdir)
        
        
        self.files_to_remove.append(self.tmpdir+"singletons.fasta")
        self.files_to_remove.append(self.tmpdir+"centroids.fasta")

        #empty map results in empty files
        store_clusters({}, "%s/tests/TestData/tiny_test.sff.txt" % PROJECT_HOME, self.tmpdir)
        actual_centroids = list(MinimalFastaParser(open(self.tmpdir+"centroids.fasta")))
        self.assertEqual(actual_centroids, [])
        actual_singletons = list(MinimalFastaParser(open(self.tmpdir+"singletons.fasta")))
        self.assertEqual(actual_singletons, [])

        #non-empty map creates non-empty files, centroids sorted by size
        mapping = {'FZTHQMS01B8T1H':[],
                   'FZTHQMS01DE1KN':['FZTHQMS01EHAJG'],
                   'FZTHQMS01EHAJG':[1,2,3]} # content doesn't really matter
        
        centroids = [('FZTHQMS01EHAJG | cluster size: 4', 'CATGCTGCCTCCCGTAGGAGTTTGGACCGTGTCTCAGTTCCAATGTGGGGGACCTTCCTCTCAGAACCCCTATCCATCGAAGGTTTGGTGAGCCGTTACCTCACCAACTGCCTAATGGAACGCATCCCCATCGATAACCGAAATTCTTTAATAACAAGACCATGCGGTCTGATTATACCATCGGGTATTAATCTTTCTTTCGAAAGGCTATCCCCGAGTTATCGGCAGGTTGGATACGTGTTACTCACCCGTGCGCCGGTCGCCA'),
                     ('FZTHQMS01DE1KN | cluster size: 2','CATGCTGCCTCCCGTAGGAGTTTGGACCGTGTCTCAGTTCCAATGTGGGGGACCTTCCTCTCAGAACCCCTATCCATCGAAGGTTTGGTGAGCCGTTACCTCACCAACTGCCTAATGGAACGCATCCCCATCGATAACCGAAATTCTTTAATAACAAGACCATGCGGTCTGATTATACCATCGGGTATTAATCTTTCTTTCGAAAGGCTATCCCCGAGTTATCGGCAGGTTGGATACGTGTTACTCACCCGTGCGCCGGTCGCCA')]

        singletons= [('FZTHQMS01B8T1H', 'CATGCTGCCTCCCGTAGGAGTTTGGACCGTGTCTCAGTTCCAATGTGGGGGACCTTCCTCTCAGAACCCCTATCCATCGAAGGTTTGGTGAGCCGTTACCTCACCAACTGCCTAATGGAACGCATCCCCATCGATAACCGAAATTCTTTAATAATTAAACCATGCGGTTTTATTATACCATCGGGTATTAATCTTTCTTTCGAAAGGCTATCCCCGAGTTATCGGCAGGTTGGATACGTGTTACTCACCCGTGCGCCGGTCGCCATCACTTA')]

        store_clusters(mapping, "%s/tests/TestData/tiny_test.sff.txt" % PROJECT_HOME, self.tmpdir)
        actual_centroids = list(MinimalFastaParser(open(self.tmpdir+"centroids.fasta")))
        self.assertEqual(actual_centroids, centroids)
        actual_singletons = list(MinimalFastaParser(open(self.tmpdir+"singletons.fasta")))
        self.assertEqual(actual_singletons,singletons)

   def test_get_representatives(self):
      """get_representatives should return the representatives as list of Sequence."""

      result= """>1: 5
ABABABA
>3: 1
BABA
>4: 1
ABABAA
>8: 2
BABBA"""
      seqs = self.data.iteritems
      mapping = self.mapping
      test_result = list(get_representatives(mapping, seqs()))
      test_result_as_fasta = "\n".join(map(lambda a: a.toFasta(),test_result))
   
      self.assertEqual(test_result_as_fasta, result)

      #another example
      mapping = {'1': ('a','b','c'),
                 '2': ('d','e','f')}
      seqs = [('1',"ACGT"), ('2', "TAGC"), ('a',"TTTTT")]
       
      observed = list(get_representatives(mapping, seqs))
      expected = [Sequence(name = ">1", seq="ACGT"), Sequence(name='2', seq="TAGC")]
      self.assertEqual(observed, expected)

   def test_squeeze_seq(self):
      """squeeze should collapse homopolymers to one nuc."""

      seq = "AAAGGGAAACCCGGGA"
      self.assertEqual(squeeze_seq(seq), "AGACGA")
      self.assertEqual(squeeze_seq("AAAATATTTAGGC"), "ATATAGC")
      self.assertEqual(squeeze_seq(""), "")
      self.assertEqual(squeeze_seq("ATGCATGCATGC"), "ATGCATGCATGC")
        
   def test_waitForFile(self):
      """waitForFile should go to sleep if file is not present."""
      
      #waitForFile has a debug/test mode, in which it raises an exception instead of going to sleep
      # should not raise anything on valid file
      try:
         waitForFile("/tmp/denoiser_utils_dummy.tmp", test_mode=True)
      except RuntimeWarning:
         self.fail("waitForFile fails on valid file")

      #but should raise on file not present
      self.assertRaises(RuntimeWarning, waitForFile, "/foo/bar/baz", test_mode=True)
         
  # def test_waitForClusterIds(self):
  #    """waitForClusterIds sleeps until jobs are finished."""
  #       
   #   try:
  #       waitForClusterIds([])
  #    except ApplicationNotFoundError:
  #       self.fail("qstat not found. Can't run on cluster.")
           
      #Can we test a real scenario with submitting a simple sleep script?

   def test_initFlowgramFile(self):
      """initFlowgramFile opens an file and writes header."""
      fh, tmp_filename = initFlowgramFile(n=100, l=400)
      self.assert_(exists(tmp_filename))
      self.tmp_filename = tmp_filename
      fh.close()
      result_file_content = list(open(tmp_filename))

      self.assertEqual(result_file_content, ["100 400\n"])


   def test_appendToFlowgramFile(self):
      """appendToFlowgram appends a flowgram to a flowgram file."""
      
      fh, tmp_filename = initFlowgramFile(n=100, l=400)
      self.assert_(exists(tmp_filename))
      self.tmp_filename = tmp_filename

      flow1 = Flowgram("0 1.2 2.1 3.4 0.02 0.01 1.02 0.08")
      appendToFlowgramFile("test_id", flow1, fh)

      flow2 = Flowgram('0.5 1.0 4.1 0.0 0.0 1.23 0.0 3.1',      
                       Name = 'a', floworder = "TACG",
                   header_info = {'Bases':'TACCCCAGGG', 'Clip Qual Right': 7,
                                  'Flow Indexes': "1\t2\t3\t3\t3\t3\t6\t8\t8\t8"})
      appendToFlowgramFile("test_id2", flow2, fh, trim=True)
      #close and re-open to read from start, seek might work as well here...
      fh.close()
      fh=open(tmp_filename)
      result_file_content = list(fh)
      self.assertEqual(result_file_content, ["100 400\n",
                                             "test_id 8 0.0 1.2 2.1 3.4 0.02 0.01 1.02 0.08\n",
                                             "test_id2 6 0.5 1.0 4.1 0.0 0.0 1.23\n"])
if __name__ == "__main__":
    main()
