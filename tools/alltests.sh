#! /bin/bash
#
#    Copyright (c) 2025 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
export PYENV_VERSION=$WEEWX_PYENV_VERSION
export PYTHONPATH=$WEEWX_PYTHONPATH

echo "**** Running UNIT Tests ****"
pytest bin/user/tests/unit

echo "**** Running FUNC Tests ****"
pytest bin/user/tests/func

echo "**** Running INTEG Tests ****"
pytest bin/user/tests/integ

echo "**** Running E2E Tests ****"
pytest bin/user/tests/e2e
