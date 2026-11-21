#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    The settings every extension repository shares, sourced by its .devenv.
#    Sourced, not executed, into the developer's shell, which may be zsh: it
#    must not change the shell options and must not depend on bash alone.
#
#    .devenv bootstraps WEEWX_TOOL_PATH, sources this file, and then exports
#    only what is specific to its repository.

# Do not inherit settings from another repository's .devenv.
unset WEEWX_MODULE_NAME WEEWX_PYTHONPATH WEEWX_LINT_PATHS WEEWX_LINT_FAIL
unset WEEWX_TEST_SUITES WEEWX_TEST_LINT_PATHS WEEWX_HTML WEEWX_RESULTS_DIR
unset WEEWX_COMMON_REPOS WEEWX_COMMON_SRC

# This file's own directory rather than the bootstrap value, so the settings
# below always come from the checkout they are read from. zsh unsets
# BASH_SOURCE and sets $0 to the sourced file instead.
_devenv_source=${BASH_SOURCE[0]:-$0}
WEEWX_TOOL_PATH="$(cd "$(dirname "${_devenv_source}")" && pwd -P)"
unset _devenv_source
export WEEWX_TOOL_PATH

. "${WEEWX_TOOL_PATH}/versions.sh" || return 1

# The development default is the oldest supported version, so a newer language
# feature fails here rather than in the oldest CI cell.
export WEEWX_PYENV_VERSION="${WEEWX_PYTHON_OLDEST}"
export PYENV_VERSION="${WEEWX_PYENV_VERSION}"

# weewx from PyPI, like CI; the sibling checkout until it is installed.
if PYTHONPATH= python3 -c 'import weewx' >/dev/null 2>&1; then
    export WEEWX_PYTHONPATH=bin
else
    export WEEWX_PYTHONPATH=bin:../weewx/src
fi

# Sourcing .devenv twice must not grow PATH.
case ":${PATH}:" in
    *":${WEEWX_TOOL_PATH}:"*) ;;
    *) PATH="${WEEWX_TOOL_PATH}:${PATH}" ;;
esac
export PATH
