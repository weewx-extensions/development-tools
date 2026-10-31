#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Lint what the CI workflow lints (its lint-paths input), with both linters,
#    and fail when either reports.
#
set -euo pipefail

. "$(dirname "$(readlink -f "$0")")/common.sh"

mkdir -p "${WEEWX_RESULTS_DIR}"

status=0
# The path list is intentionally unquoted, it holds several files.
# shellcheck disable=SC2086
pylint ${WEEWX_LINT_PATHS} -r n --msg-template="{path}:{line}: [{msg_id}({symbol}), {obj}] {msg}" \
    | tee "${WEEWX_RESULTS_DIR}/pylint.txt" || status=$?

# shellcheck disable=SC2086
flake8 ${WEEWX_LINT_PATHS} | tee "${WEEWX_RESULTS_DIR}/flake8.txt" || status=$?

exit "${status}"
