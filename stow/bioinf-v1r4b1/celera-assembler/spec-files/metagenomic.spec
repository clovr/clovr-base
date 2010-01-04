# We can assemble environmental samples of DNA such as the bacterial fraction of open ocean water. For metagenomics assemblies, we use very low stringency alignments. Clearly, low stringency will 
# enable reads from different species to co-assemble into the same contigs. This is a necessary trade-off if samples are high in sequence diversity, high in population complexity, and low in strain 
# abundance.

#
# METAGENOMICS SETTINGS
#
# Low-stringency alignment.
utgErrorRate=0.12
ovlErrorRate=0.14
cnsErrorRate=0.14
cgwErrorRate=0.14
# Low-stringency overlap seeds.
merSize=14
# Use as many low-quality bases as possible.
doExtendClearRanges=2
doOverlapTrimming=1
# Place reads in repeats if possible.
doResolveSurrogates=1
# Don't correct minority reads to match the majority.
doFragmentCorrection=0
# Don't try to merge haplotypes. 
utgBubblePopping=0
# Establish an expectation for the size of the assembly.
# Use this to control sensitivity to high-coverage regions.
# Normally, high-coverage unitigs are treated suspiciously, leading to smaller contigs.
# In single-genome assemblies, high coverage unitigs might be collapsed repeats.
# Assembling across collapsed repeats induces chimera, the worst form of mis-assembly.
# In single-genome assemblies, we do NOT set this parameter!!!
# In metagenomics, our choice depends on population complexity and abundance. 
# Small genome size => high coverage ok => high-coverage unitigs will be considered unique.
# Large genome size => high coverage unusual => high-coverage unitigs will be treated suspiciously.
utgGenomeSize=50000000     # Here, expect 50Mbp in scaffolds.
#
# COMPONENT OPTIONS 
#
merylMemory  = 4000   # That is 4GB
merylThreads = 2
#
overlapper = ovl
ovlMemory        = 4GB --hashload 0.7 --hashstrings 60000
ovlThreads       = 2
ovlHashBlockSize = 180000
ovlRefBlockSize  = 4000000
#
unitigger=utg
#
cnsConcurrency=4   # Launch 4 consensus jobs at a time, ideal for quad-core CPU.

fakeUIDs = 1 
