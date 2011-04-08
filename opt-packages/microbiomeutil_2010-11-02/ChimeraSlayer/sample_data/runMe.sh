#!/bin/sh

# remove any preexisting outputs from an earlier run.
rm chims.NAST.CPS*
rm tmp.*

../ChimeraSlayer.pl --query_NAST chims.NAST --printCSalignments --printFinalAlignments 


