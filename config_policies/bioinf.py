##
# Ensure bioinformatics tools exists and are installed

# Just pull everything from policy
from igs.config_manage.policy import *

PKG_NAME = 'bioinf-v1r4b1'
PKG_DIR = '${opt.package_dir}/' + PKG_NAME

ensureOptPkg(PKG_NAME)
##
# we don't want to kill this now, so we'll back it up and then link our package there
run('mv /usr/local/bioinf /usr/local/bioinf.bak')
run('ln -s %s /usr/local/bioinf' % PKG_DIR)

