#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
set -euo pipefail

. "$(dirname "$(readlink -f "$0")")/common.sh"

# The integration suite's utils module collides with other test directories,
# so CI imports the modules by their path.
run_tests integ --import-mode=append
