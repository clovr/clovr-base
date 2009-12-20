##
# Ensure bioinformatics tools exists and are installed

# Just pull everything from policy
from igs.config_manage.policy import *

PKG_NAME = 'bioinf-v1r2b1'
PKG_DIR = '${opt.package_dir}/' + PKG_NAME

##
# Turning this off for right now
import sys
sys.exit(0)

ensureOptPkg(PKG_NAME)
run('mv /usr/local/bioinf /usr/local/bioinf.bak')
run('ln -s %s /usr/local/bioinf' % (PKG_DIR + PKG_NAME))

