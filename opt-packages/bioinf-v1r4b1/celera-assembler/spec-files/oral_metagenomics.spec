
################################################################################
#
#  This is a Celera Assembler specFile.  It contains options
#  to the assembler, packaged together into one file.  Any option
#  given to the assembler on the command line can go here; for example:
#
#    sge                   = -A assembly -P 338153
#    sgeScript             = -pe threaded 1 -l arch=lx*64 -l memory=6G
#    sgeOverlap            = -pe threaded 4 -l arch=lx*64 -l memory=4G -p -25
#    sgeConsensus          =                -l arch=lx*64 -l memory=2G -p -25
#
#  See the runCA documentation for the options.
#
################################################################################
#


# A sample spec file for assembling metagenomics / environmental
# samples, from Sanger reads.

#  Increase the error rates to build unitigs with 12% error overlaps, and
#  allow 14% error globally.

utgErrorRate=0.12
ovlErrorRate=0.14
cnsErrorRate=0.14
cgwErrorRate=0.14

# Disable bubble popping.  Unreliable and/or WRONG for environmental
# samples.

utgBubblePopping=0

# Use a smaller mer size to encourage finding overlaps at 14% error,
# both for OBT and OVL.

merSize=14


# Fragment correction is unreliable with low coverage and/or
# environmental samples.  Disable.

doFragmentCorrection=0

# We only want ONE iteration of clear range extension; the default is 2 iterations.

doResolveSurrogates=1
doExtendClearRanges=1


#454 st


doOverlapTrimming=1 
unitigger=utg

fakeUIDs=1

merylMemory  = 8000   # That is 4GB
#

ovlMerThreshold = 100
overlapper = mer # ovl
merOverlapperExtendConcurrency =8
merOverlapperSeedConcurrency = 8
merOverlapperSeedBatchSize = 200000

obtMerThreshold = 100
ovlCorrConcurrency =8



#Using the Grid
useGrid=1
scriptOnGrid=0
maxGridJobSize= 100
sgeScript             = -l mem_free=4G    # all non-parallel operations
sgeOverlap            = -l mem_free=4G    # both runs of overlapper
sgeFragmentCorrection = -l mem_free=4G
sgeOverlapCorrection  = -l mem_free=4G 
sgeConsensus          = -l mem_free=4G    # both runs of consensus

