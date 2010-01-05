##
# Ensure hadoop exists and is installed

# Just pull everything from policy
from igs.config_manage.policy import *

PKG_NAME = 'bowtie-0.12.0'

ensureOptPkg(PKG_NAME)

installOptPkg(PKG_NAME)
