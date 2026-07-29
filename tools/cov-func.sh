#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
export PYENV_VERSION=$WEEWX_PYENV_VERSION
export PYTHONPATH=$WEEWX_PYTHONPATH

coverage run --branch -m pytest bin/user/tests/func; 

coverage html --include 'bin/user/*.py' --omit bin/user/__init__.py
