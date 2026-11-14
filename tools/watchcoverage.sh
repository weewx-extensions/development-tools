#! /bin/bash
#
#    Copyright (c) 2025 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Report coverage, and again whenever this script, coverage.sh, the module,
#    or the unit tests change.
#
set -euo pipefail

. "$(cd "$(dirname "$0")" && pwd -P)/common.sh"

watch_and_run "${WEEWX_TOOL_PATH}/coverage.sh" \
    "${WEEWX_TOOL_PATH}/watchcoverage.sh" \
    "${WEEWX_TOOL_PATH}/coverage.sh" \
    "bin/user/${WEEWX_MODULE_NAME}.py" \
    bin/user/tests/unit
