#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Lint what the CI workflow lints (its lint-paths input) and the tests, with
#    both linters, and fail when either reports.
#
set -euo pipefail

. "$(cd "$(dirname "$0")" && pwd -P)/common.sh"

mkdir -p "${WEEWX_RESULTS_DIR}"

pylint_flags=(-r n '--msg-template={path}:{line}: [{msg_id}({symbol}), {obj}] {msg}')
status=0

# The path lists are intentionally unquoted, they hold several files.
# shellcheck disable=SC2086
pylint ${WEEWX_LINT_PATHS} "${pylint_flags[@]}" \
    | tee "${WEEWX_RESULTS_DIR}/pylint.txt" || status=$?

# shellcheck disable=SC2086
flake8 ${WEEWX_LINT_PATHS} | tee "${WEEWX_RESULTS_DIR}/flake8.txt" || status=$?

if [ -n "${WEEWX_TEST_LINT_PATHS}" ] && [ -d "${WEEWX_TEST_LINT_PATHS}" ] && [ -f .pylintrc-tests ]; then
    # shellcheck disable=SC2086
    pylint ${WEEWX_TEST_LINT_PATHS} "${pylint_flags[@]}" --rcfile .pylintrc-tests \
        | tee "${WEEWX_RESULTS_DIR}/pylint-tests.txt" || status=$?

    # shellcheck disable=SC2086
    flake8 ${WEEWX_TEST_LINT_PATHS} | tee "${WEEWX_RESULTS_DIR}/flake8-tests.txt" || status=$?
fi

if [ "${WEEWX_LINT_FAIL}" != "1" ]; then
    echo "WEEWX_LINT_FAIL is not 1, reporting the findings without failing."
    exit 0
fi

exit "${status}"
