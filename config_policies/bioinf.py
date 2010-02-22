##
# Ensure bioinformatics tools exists and are installed

# Just pull everything from policy
from igs.config_manage.policy import *

PKG_NAME = 'bioinf-v1r4b1'
PKG_DIR = '${opt.package_dir}/' + PKG_NAME

def startup():
    ensureOptPkg(PKG_NAME)
    run('ln -s %s /usr/local/bioinf' % PKG_DIR)


def shutdown():
    run('rm /usr/local/bioinf')
    


