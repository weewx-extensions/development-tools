#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Defaults shared by the tools scripts. Sourced, not executed.
#
#    The settings mirror the repository's analyze-test workflow inputs.
#    WEEWX_MODULE_NAME, WEEWX_LINT_PATHS, WEEWX_TEST_SUITES, WEEWX_HTML,
#    WEEWX_RESULTS_DIR, and WEEWX_PYTHONPATH are normally set in .devenv.

WEEWX_PYTHONPATH=${WEEWX_PYTHONPATH:-bin}
WEEWX_RESULTS_DIR=${WEEWX_RESULTS_DIR:-results}
WEEWX_HTML=${WEEWX_HTML:-0}
WEEWX_TEST_SUITES=${WEEWX_TEST_SUITES:-unit func integ e2e}
# The tests are linted with .pylintrc-tests; set to '' to skip them.
WEEWX_TEST_LINT_PATHS=${WEEWX_TEST_LINT_PATHS-bin/user/tests}

if [ -z "${WEEWX_LINT_PATHS:-}" ]; then
    if [ -z "${WEEWX_MODULE_NAME:-}" ]; then
        echo "Set WEEWX_LINT_PATHS or WEEWX_MODULE_NAME in .devenv." >&2
        return 1
    fi
    WEEWX_LINT_PATHS="bin/user/${WEEWX_MODULE_NAME}.py"
fi

# weewx, configobj, paho, etc. are installed, so only the checkout is added.
export PYTHONPATH="${WEEWX_PYTHONPATH}${PYTHONPATH:+:${PYTHONPATH}}"

if [ -n "${WEEWX_PYENV_VERSION:-}" ]; then
    export PYENV_VERSION=${WEEWX_PYENV_VERSION}
fi

run_tests() {
    local suite=$1
    shift

    local suite_path="bin/user/tests/${suite}"
    if [ ! -d "${suite_path}" ]; then
        echo "Skipping the ${suite} tests, ${suite_path} does not exist."
        return 0
    fi

    local pytest_args=("${suite_path}" "$@")

    if [ "${WEEWX_HTML}" == "1" ]; then
        mkdir -p "${WEEWX_RESULTS_DIR}"
        pytest_args+=("--html=${WEEWX_RESULTS_DIR}/${suite}tests.html" "--self-contained-html")
    fi

    pytest "${pytest_args[@]}"
}
