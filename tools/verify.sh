#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Run the environment check, the linters, and the tests, reporting every
#    step's result rather than stopping at the first failure.
#
set -uo pipefail

TOOLS_DIR="$(dirname "$(readlink -f "$0")")"

status=0
failed=''

for step in checkenv lint alltests; do
    echo "**** Running ${step} ****"
    if "${TOOLS_DIR}/${step}.sh"; then
        echo "**** ${step} passed ****"
    else
        echo "**** ${step} failed ****"
        failed="${failed} ${step}"
        status=1
    fi
    echo
done

if [ "${status}" -ne 0 ]; then
    echo "Failed:${failed}"
fi

exit "${status}"
