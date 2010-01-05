##
# Ensure hadoop exists and is installed

# Just pull everything from policy
from igs.config_manage.policy import *

PKG_NAME = 'crossbow-0.1.3'

ensureOptPkg(PKG_NAME)

installOptPkg(PKG_NAME)
