#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Run the environment check, the linters, the config check, and the tests,
#    reporting every step's result rather than stopping at the first failure.
#
set -uo pipefail

TOOLS_DIR="$(dirname "$(readlink -f "$0")")"

status=0
failed=''

run() {
    local name=$1
    shift

    echo "**** Running ${name} ****"
    if "$@"; then
        echo "**** ${name} passed ****"
    else
        echo "**** ${name} failed ****"
        failed="${failed} ${name}"
        status=1
    fi
    echo
}

run checkenv "${TOOLS_DIR}/checkenv.sh"
run lint "${TOOLS_DIR}/lint.sh"
run configs "${TOOLS_DIR}/configs.sh" --check
run alltests "${TOOLS_DIR}/alltests.sh"

if [ "${status}" -ne 0 ]; then
    echo "Failed:${failed}"
fi

exit "${status}"
