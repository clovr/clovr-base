##

# Just pull everything from policy
from igs.config_manage.policy import *

def startup():
    dirExists('${dirs.upload_dir}')
    dirExists('${dirs.tag_dir}')
    dirOwner('${dirs.upload_dir}', 'www-data')
    dirOwner('${dirs.tag_dir}', 'www-data')

def shutdown():
    pass
