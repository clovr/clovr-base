##
# Ensure bioinformatics tools exists and are installed

# Just pull everything from policy
from igs.config_manage.policy import *

PKG_NAME = 'bioinf-v1r4b1'
PKG_DIR = '${opt.package_dir}/' + PKG_NAME

def startup():
    ensureOptPkg(PKG_NAME)
    # Just get rid of this dir, for now
    run('rm -rf /usr/local/bioinf')
    run('ln -s %s /usr/local/bioinf' % PKG_DIR)


def shutdown():
    run('rm /usr/local/bioinf')
    


