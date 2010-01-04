
# Mammalian genomes are plagued with repeats. Use a combination of read lengths and pair-end distances such that most repeats will be spanned by random sampling. Sequence one individual.
# Normally, use of the grid is essential for both overlapper and consensus. These are the fan-out stages of the pipeline, and they make use of the extra nodes available on a grid.
# In an NFS environment, overlapper very quickly overwhelms the NFS server. You can increase both the hash size (the number of fragments "in core") and the reference block size (the number of 
# fragments "per job"). To accommodate this, we need to use a carefully constructed ovlMemory string that overrides some reasonable defaults.
# Fragment correction benefits greatly by increasing the batch size. See the frgCorrBatchSize below for details. In this example, the batch size is small. In most environments, it would be acceptable 
# to submit such small jobs to all available compute nodes. 


useGrid=1
ovlMemory=2GB --hashload 0.8 --hashstrings 110000
ovlHashBlockSize=600000
ovlRefBlockSize=7630000
frgCorrBatchSize=1000000
frgCorrThreads=4
fakeUIDs = 1 
