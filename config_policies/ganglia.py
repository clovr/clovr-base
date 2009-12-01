##
# This describes what needs to exist in order for ganglia to be properly run
import time

# Just pull everything from policy
from igs.config_manage.policy import *

PKG_NAME = 'ganglia-3.1.2'

ensurePkg(PKG_NAME)
dirExists('/var/lib/ganglia/rrds')
fileExists('/var/www/ganglia')
dirOwner('/var/lib/ganglia/rrds', 'nobody')
executePkgTemplate(PKG_NAME, 'etc/gmetad.conf.tmpl')
executePkgTemplate(PKG_NAME, 'etc/gmond.conf.tmpl')
installPkg(PKG_NAME)
run('gmond --conf=${stow.base_dir}/etc/gmond.conf')
run('gmetad --conf=${stow.base_dir}/etc/gmetad.conf')

##
# I have no idea why this happens but for some reason I need to rerun these commands...
time.sleep(10)
run('killall gmond')
run('killall gmetad')

run('gmond --conf=${stow.base_dir}/etc/gmond.conf')
run('gmetad --conf=${stow.base_dir}/etc/gmetad.conf')
