##

# Just pull everything from policy
from igs.config_manage.policy import *

PKG_NAME = 'tophat-1.0.12'

ensurePkg(PKG_NAME)
installPkg(PKG_NAME)
