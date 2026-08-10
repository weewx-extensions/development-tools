#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#

""" Installer.

To uninstall run
wee_extension --uninstall=simpleclass
"""

from io import StringIO

import configobj

from weecfg.extension import ExtensionInstaller

VERSION = "0.1.0-rc01"

CONFIG = """
"""

def loader():
    """ Load and return the extension installer. """
    return SimpleClassInstaller()

class SimpleClassInstaller(ExtensionInstaller):
    """ The extension installer. """
    def __init__(self):

        install_dict = {
            'version': VERSION,
            'name': 'SimpleClass',
            # add a leading space, so that long versions does not run into the description
            'description': ' Test install.',
            'author': "Rich Bell",
            'author_email': "bellrichm@gmail.com",
            'files': [('bin/user', ['bin/user/simpleclass.py',
                                    ])]
        }

        config_dict = configobj.ConfigObj(StringIO(CONFIG))
        install_dict['config'] = config_dict

        super().__init__(install_dict)
