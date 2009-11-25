##
# This describes what needs to exist in order for ganglia to be properly run

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
run('gmond --conf=${base.dir}/etc/gmond.conf')
run('gmetad --conf=${base.dir}/etc/gmetad.conf')


