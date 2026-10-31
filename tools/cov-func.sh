#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Measure the function tests' coverage, and emit the reports the CI uploads.
#
set -euo pipefail

. "$(dirname "$(readlink -f "$0")")/common.sh"

coverage run --branch -m pytest bin/user/tests/func

mkdir -p "${WEEWX_RESULTS_DIR}"
coverage html --include 'bin/user/*.py' --omit bin/user/__init__.py -d "${WEEWX_RESULTS_DIR}/coverage"
coverage xml --include 'bin/user/*.py' --omit bin/user/__init__.py
