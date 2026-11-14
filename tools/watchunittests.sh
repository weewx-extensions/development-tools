#! /bin/bash
#
#    Copyright (c) 2025 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Run the unit tests, and again whenever this script, unittests.sh, the
#    module, or the tests change.
#
set -euo pipefail

. "$(cd "$(dirname "$0")" && pwd -P)/common.sh"

watch_and_run "${WEEWX_TOOL_PATH}/unittests.sh" \
    "${WEEWX_TOOL_PATH}/watchunittests.sh" \
    "${WEEWX_TOOL_PATH}/unittests.sh" \
    "bin/user/${WEEWX_MODULE_NAME}.py" \
    bin/user/tests/unit
