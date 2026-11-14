#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Defaults shared by the tools scripts. Sourced, not executed.
#
#    The settings mirror the repository's analyze-test workflow inputs.
#    WEEWX_MODULE_NAME, WEEWX_LINT_PATHS, WEEWX_LINT_FAIL, WEEWX_TEST_SUITES,
#    WEEWX_HTML, WEEWX_RESULTS_DIR, and WEEWX_PYTHONPATH are normally set in
#    .devenv.

WEEWX_PYTHONPATH=${WEEWX_PYTHONPATH:-bin}
WEEWX_RESULTS_DIR=${WEEWX_RESULTS_DIR:-results}
WEEWX_HTML=${WEEWX_HTML:-0}
# Mirrors the workflow's lint-fail input; 0 reports the findings without failing.
WEEWX_LINT_FAIL=${WEEWX_LINT_FAIL:-1}
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

# Run a command, then again whenever one of the watched paths changes.
# A suite writes into the tree it reads (__pycache__, reports), so the
# timestamp is taken after each run rather than before it.
watch_and_run() {
    local command=$1
    shift

    local stamp
    stamp="$(mktemp "${TMPDIR:-/tmp}/weewx-watch.XXXXXX")"
    trap 'rm -f "${stamp}"' EXIT

    "${command}"
    touch "${stamp}"
    echo "Watching $* for changes. Ctrl-C to stop."

    while :; do
        if find "$@" -newer "${stamp}" -print 2>/dev/null | grep -q .; then
            "${command}"
            touch "${stamp}"
        fi
        sleep 1
    done
}
