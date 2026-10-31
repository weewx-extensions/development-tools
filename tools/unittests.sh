#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
set -euo pipefail

. "$(dirname "$(readlink -f "$0")")/common.sh"

run_tests unit
