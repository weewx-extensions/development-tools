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

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${TOOLS_DIR}/common.sh"
. "${TOOLS_DIR}/versions.sh"

# The workflow lints only its newest cell, and requirements.txt pins pylint 4,
# which needs Python 3.10 or later. pylint 3 also counts `self` as a positional
# argument and reports findings pylint 4 does not, so linting under the older
# development default would fail on code CI passes. Lint on the newest version
# the project supports, whatever interpreter the tests run on.
if command -v pyenv >/dev/null 2>&1; then
    if ! PYENV_VERSION="${WEEWX_PYTHON_LATEST}" pyenv version-name >/dev/null 2>&1; then
        echo "lint.sh: python ${WEEWX_PYTHON_LATEST} is not installed; it is the version the lint runs on." >&2
        exit 2
    fi
fi
export PYENV_VERSION="${WEEWX_PYTHON_LATEST}"

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
