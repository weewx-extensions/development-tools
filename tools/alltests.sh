#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Run each suite in turn, stopping at the first failure like CI.
#
set -euo pipefail

. "$(dirname "$(readlink -f "$0")")/common.sh"

# The suite list is intentionally unquoted, it holds several names.
# shellcheck disable=SC2086
for suite in ${WEEWX_TEST_SUITES}; do
    echo "**** Running ${suite^^} Tests ****"
    if [ "${suite}" == "integ" ]; then
        run_tests "${suite}" --import-mode=append
    else
        run_tests "${suite}"
    fi
done
