#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Read the Python versions this project supports from supported-pythons,
#    beside this script, and with --check report a copy of them that disagrees.
#
#    The first entry in that file is the oldest and the development default; the
#    last is the latest. Sourced, this file only defines variables and one
#    function: it must not change the caller's shell options.
#
#    devenv.sh sources it from the developer's shell, which may be zsh, so this
#    half avoids bash-only array indexing and the direct run below is the only
#    place that touches the shell options.
#
# zsh unsets BASH_SOURCE and sets $0 to the sourced file instead.
_versions_source=${BASH_SOURCE[0]:-$0}
WEEWX_VERSIONS_FILE="$(cd "$(dirname "${_versions_source}")" && pwd -P)/supported-pythons"

WEEWX_PYTHON_OLDEST=''
WEEWX_PYTHON_LATEST=''
WEEWX_PYTHON_MATRIX=()
if [ -f "${WEEWX_VERSIONS_FILE}" ]; then
    while IFS= read -r _versions_line; do
        _versions_line="${_versions_line%%#*}"
        _versions_line="${_versions_line//[[:space:]]/}"
        if [ -n "${_versions_line}" ]; then
            if [ -z "${WEEWX_PYTHON_OLDEST}" ]; then
                WEEWX_PYTHON_OLDEST=${_versions_line}
            fi
            WEEWX_PYTHON_LATEST=${_versions_line}
            WEEWX_PYTHON_MATRIX+=("${_versions_line}")
        fi
    done < "${WEEWX_VERSIONS_FILE}"
fi
unset _versions_line

if [ ! -f "${WEEWX_VERSIONS_FILE}" ] || [ "${#WEEWX_PYTHON_MATRIX[@]}" -eq 0 ]; then
    echo "versions.sh: ${WEEWX_VERSIONS_FILE} is missing or has no versions" >&2
    unset WEEWX_VERSIONS_FILE _versions_source
    if [ -n "${ZSH_VERSION:-}" ] || [ "${_versions_source}" != "$0" ]; then
        return 1
    fi
    exit 1
fi

unset WEEWX_VERSIONS_FILE

# Whether a full version (3.10.22) is supported. A minor-series entry matches
# by prefix, so the installed patch release need not equal the entry.
weewx_python_supported() {
    local version=$1
    local entry
    for entry in "${WEEWX_PYTHON_MATRIX[@]}"; do
        if [ "${version}" = "${entry}" ] || [ "${version#${entry}.}" != "${version}" ]; then
            return 0
        fi
    done
    return 1
}

# Sourcing stops here; the checks below belong to a direct run. zsh unsets
# BASH_SOURCE and sets $0 to the sourced file, so the shell has to say which is
# which before this file can run its checks.
if [ -n "${ZSH_VERSION:-}" ] || [ "${_versions_source}" != "$0" ]; then
    unset _versions_source
    return 0
fi
unset _versions_source
set -uo pipefail

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd -P)"
DEVTOOLS_DIR="$(dirname "${TOOLS_DIR}")"
WORKFLOWS_DIR="${DEVTOOLS_DIR}/.github/workflows"

usage() {
    cat <<'EOF'
Usage: versions.sh [--check]

  --check     Report the workflow and the .devenv copies that disagree with
              supported-pythons, and a .devenv that pins a version instead of
              sourcing devenv.sh.
  -h, --help  Show this message.
EOF
}

check=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        --check)
            check=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "versions.sh: unknown argument '$1'." >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

if [ "${check}" -eq 0 ]; then
    echo "oldest  ${WEEWX_PYTHON_OLDEST}"
    echo "latest  ${WEEWX_PYTHON_LATEST}"
    echo "matrix  ${WEEWX_PYTHON_MATRIX[*]}"
    exit 0
fi

join() {
    local IFS=' '
    echo "$*"
}

# The quoted list of the workflow's python-version matrix, joined by spaces.
workflow_matrix() {
    sed -n 's/^ *python-version: *\[\(.*\)\].*$/\1/p' "$1" |
        head -1 |
        tr ',' '\n' |
        sed 's/[][",[:space:]]//g' |
        tr '\n' ' ' |
        sed 's/ *$//'
}

# The default of the named workflow input, without its quotes.
workflow_default() {
    awk -v key="$2" '
        $1 == key ":" { found = 1; next }
        found && $1 == "default:" { print; exit }
    ' "$1" | sed "s/.*default: *//; s/['\"]//g"
}

status=0

matrix_workflow="${WORKFLOWS_DIR}/analyze-test-matrix.yml"
if [ ! -f "${matrix_workflow}" ]; then
    echo "versions.sh: ${matrix_workflow} is missing" >&2
    exit 1
fi

expected=$(join "${WEEWX_PYTHON_MATRIX[@]}")
# A workflow that calls the reusable one carries no list, so an absent
# python-version matrix is not a problem; a literal one has to agree.
check_matrix() {
    local workflow=$1
    local found
    found=$(workflow_matrix "${workflow}")
    if [ -n "${found}" ] && [ "${found}" != "${expected}" ]; then
        echo "${workflow}: python-version is '${found}', should be '${expected}'"
        status=1
    fi
}
check_matrix "${matrix_workflow}"

# analyze-test.yml runs a single cell and takes its version from this default;
# the matrix workflow passes the same default to every non-matrix cell.
for workflow in "${WORKFLOWS_DIR}/analyze-test-matrix.yml" "${WORKFLOWS_DIR}/analyze-test.yml"; do
    [ -f "${workflow}" ] || continue
    default=$(workflow_default "${workflow}" 'latest-python-version')
    if [ "${default}" != "${WEEWX_PYTHON_LATEST}" ]; then
        echo "${workflow}: latest-python-version is '${default}', should be '${WEEWX_PYTHON_LATEST}'"
        status=1
    fi
done

# The template is canonical for the consumers; a consumer's own .devenv is
# checked too, because it is a copy that can drift on its own.
check_devenv() {
    local file=$1
    [ -f "${file}" ] || return 0
    if ! grep -q 'devenv\.sh' "${file}"; then
        echo "${file}: does not source devenv.sh." >&2
        status=1
    fi
    if grep -Eq '^[[:space:]]*(export[[:space:]]+)?WEEWX_PYENV_VERSION=' "${file}"; then
        echo "${file}: sets WEEWX_PYENV_VERSION; devenv.sh takes it from supported-pythons." >&2
        status=1
    fi
}
check_devenv "${DEVTOOLS_DIR}/.devenv-template"
# A consumer keeps its own .devenv and may keep its own literal matrix; check
# both. development-tools itself has neither, only the template above.
if [ "$(pwd -P)" != "$(cd "${DEVTOOLS_DIR}" && pwd -P)" ]; then
    for workflow in .github/workflows/*.yml; do
        [ -f "${workflow}" ] || continue
        check_matrix "${workflow}"
    done
    check_devenv .devenv
fi

exit "${status}"
