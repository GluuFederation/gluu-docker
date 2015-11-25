# Uncomment the following lines if you are going to use virtualenv
"""
activate_this = '/var/www/gluu-webui/env/bin/activate_this.py'
execfile(activate_this, dict(__file__=activate_this))

import sys
path = '/var/www/gluu-webui/'
if path not in sys.path:
    sys.path.insert(0, path)
"""
import sys
sys.path.insert(0, '/app')
from gluuwebui import app as application
