#!/usr/bin/env python
"""tests for denoiser functions
"""
from os import remove, rmdir
from cogent.util.unit_test import TestCase, main
from shutil import rmtree
#import as _main to not interfere with TestCase.main
from Denoiser.denoiser import main as _main
from Denoiser.settings import PROJECT_HOME

class DenoiserTests(TestCase):

    def setUp(self):
        self.test_dir = "denoiser_main_test/"
        self.expected = """>FZTHQMS01CBFZS | cluster size: 96 
CTCCCGTAGGAGTTTGGACCGTGTCTCAGTTCCAATGTGGGGGACCTTCCTCTCAGAACCCCTATCCATCGAAGGTTTGGTGAGCCGTTACCTCACCAACTGCCTAATGGAACGCATCCCCATCGATAACCGAAATTCTTTAATAACAAGACCATGCGGTCTGATTATACCATCGGGTATTAATCTTTCTTTCGAAAGGCTATCCCCGAGTTATCGGCAGGTTGGATACGTGTTACTCACCCGTGCGCCGGTCGCCA
>FZTHQMS01D5GNH | cluster size: 14 
CTCCCGTAGGAGTTTGGACCGTGTCTCAGTTCCAATGTGGGGGACCTTCCTCTCAGAACCCCTATCCATCGAAGGTTTGGTGAGCCGTTACCTCACCAACTGCCTAATGGAACGCATCCCCATCGATAACCGAAATTCTTTAATAATTAAACCATGCGGTTTTATTATACCATCGGGTATTAATCTTTCTTTCGAAAGGCTATCCCCGAGTTATCGGCAGGTTGGATACGTGTTACTCACCCGTGCGCCGGTCGCCATCACTTA
"""

        self.expected_map_string= """FZTHQMS01CBFZS:\tFZTHQMS01EBR1Z\tFZTHQMS01DE1KN\tFZTHQMS01EFGIH\tFZTHQMS01EET7Y\tFZTHQMS01C3OST\tFZTHQMS01DS0EF\tFZTHQMS01DA0J2\tFZTHQMS01EHAJG\tFZTHQMS01BVWEA\tFZTHQMS01AY846\tFZTHQMS01D7G0F\tFZTHQMS01ANJNP\tFZTHQMS01EUDWX\tFZTHQMS01D75QS\tFZTHQMS01DX4K7\tFZTHQMS01DN9PU\tFZTHQMS01D7ROY\tFZTHQMS01B7EOD\tFZTHQMS01B48L4\tFZTHQMS01B7LPY\tFZTHQMS01EVXXL\tFZTHQMS01CS3HK\tFZTHQMS01DL73H\tFZTHQMS01ASQF6\tFZTHQMS01DAW6I\tFZTHQMS01D44VK\tFZTHQMS01EX5R3\tFZTHQMS01EXNYO\tFZTHQMS01EFY2G\tFZTHQMS01CIW5N\tFZTHQMS01D9NPX\tFZTHQMS01A9L7K\tFZTHQMS01C3L8U\tFZTHQMS01CTVU4\tFZTHQMS01EFR3X\tFZTHQMS01BUQUB\tFZTHQMS01CD5X4\tFZTHQMS01DC6Y2\tFZTHQMS01DB2PR\tFZTHQMS01A5NRR\tFZTHQMS01E05DM\tFZTHQMS01D17U9\tFZTHQMS01B89CA\tFZTHQMS01BX7IN\tFZTHQMS01E1UUW\tFZTHQMS01COVIG\tFZTHQMS01CXAEJ\tFZTHQMS01DDD2L\tFZTHQMS01CHUP3\tFZTHQMS01C0G4W\tFZTHQMS01EFXQI\tFZTHQMS01DANHO\tFZTHQMS01BWOHY\tFZTHQMS01BYM9B\tFZTHQMS01EA5DQ\tFZTHQMS01D6FUN\tFZTHQMS01D2KUT\tFZTHQMS01EJBVG\tFZTHQMS01DZNVR\tFZTHQMS01DFZ66\tFZTHQMS01BH4Y2\tFZTHQMS01ADP0X\tFZTHQMS01D5AA5\tFZTHQMS01DP7D8\tFZTHQMS01A5JN6\tFZTHQMS01DY4WA\tFZTHQMS01DQP52\tFZTHQMS01BPLFB\tFZTHQMS01C3PY2\tFZTHQMS01EALSY\tFZTHQMS01AVZVP\tFZTHQMS01CU4P8\tFZTHQMS01BXXPI\tFZTHQMS01DSWPH\tFZTHQMS01DR0XI\tFZTHQMS01DCRIO\tFZTHQMS01DNJ1G\tFZTHQMS01EQ4UZ\tFZTHQMS01C70SU\tFZTHQMS01DOX93\tFZTHQMS01CGVWJ\tFZTHQMS01D9E0Z\tFZTHQMS01CWLO1\tFZTHQMS01ED48N\tFZTHQMS01ECPA7\tFZTHQMS01EDIVS\tFZTHQMS01CBSWG\tFZTHQMS01BUD3Y\tFZTHQMS01C9YX4\tFZTHQMS01CCHXJ\tFZTHQMS01B92AM\tFZTHQMS01DVGXE\tFZTHQMS01E2O1U\tFZTHQMS01B1L2U\tFZTHQMS01C0NTD
FZTHQMS01D5GNH:\tFZTHQMS01EIKSO\tFZTHQMS01EPYEY\tFZTHQMS01CLPPP\tFZTHQMS01DY8JU\tFZTHQMS01CWHS4\tFZTHQMS01A8PF5\tFZTHQMS01DVHAZ\tFZTHQMS01EHJ2Q\tFZTHQMS01AWLGH\tFZTHQMS01B8T1H\tFZTHQMS01C7Q06\tFZTHQMS01DS2TS\tFZTHQMS01DQMHI
"""

    def tearDown(self):
        """remove tmp files"""        
        if hasattr(self, "result_dir") and self.result_dir:
            rmtree(self.result_dir)
        try:
            rmdir(self.test_dir)
        except OSError:
            #directory probably not empty, better not remove
            pass
        #kill all workers

    
    def test_main(self):
        """Denoiser should always give same result on test data"""

        args =  ["denoiser.py", "--force","-i", "%s/tests/TestData/tiny_test.sff.txt" % PROJECT_HOME, "-o", self.test_dir]
        self.result_dir = _main(args)

        observed = "".join(list(open(self.result_dir+ "centroids.fasta")))
        self.assertEqual(observed, self.expected)

        observed = "".join(list(open(self.result_dir+ "denoiser_mapping.txt")))
        self.assertEqual(observed,self.expected_map_string)
        

    def test_main_on_cluster(self):
        """Denoiser works in a cluster environment."""
        
        args =  ["denoiser.py",  "--force", "-i", "%s/tests/TestData/tiny_test.sff.txt" % PROJECT_HOME, 
                 "-o", self.test_dir, "-c", "-n", "2"]
        self.result_dir = _main(args)
        observed = "".join(list(open(self.result_dir+ "centroids.fasta")))
        self.assertEqual(observed, self.expected)     

    def test_main_on_cluster_low_mem(self):
        """Denoiser works using low_memory."""
        
        args =  ["denoiser.py", "--force", "-i", "%s/tests/TestData/tiny_test.sff.txt" % PROJECT_HOME,
                 "-o", self.test_dir, "--low_memory"]
        self.result_dir = _main(args)
        observed = "".join(list(open(self.result_dir+ "centroids.fasta")))
        self.assertEqual(observed, self.expected)

if __name__ == "__main__":
    main()
