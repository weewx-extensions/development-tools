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

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd -P)"

usage() {
    cat <<'EOF'
Usage: verify.sh [--python VERSION]...

  --python VERSION  Run the environment check and the test suites on this
                    pyenv version. Repeat the option to cover several, for
                    example the oldest and the newest. Lint and the static
                    checks run once, as the workflow lints a single cell.
  -h, --help        Show this message.
EOF
}

# Replace the requested names with the versions pyenv resolves them to, so a
# prefix such as '3.9' names the installed 3.9.x, and stop when one is missing.
resolve_pyenv_versions() {
    if ! command -v pyenv >/dev/null 2>&1; then
        echo "verify.sh: pyenv is not on PATH." >&2
        exit 2
    fi

    local resolved
    resolved=()
    local version
    local name
    for version in "${pyenv_versions[@]}"; do
        if ! name=$(PYENV_VERSION="${version}" pyenv version-name 2>/dev/null) || [ -z "${name}" ]; then
            echo "verify.sh: python ${version} is not installed, run 'pyenv install ${version}'." >&2
            exit 2
        fi
        resolved+=("${name}")
    done
    pyenv_versions=("${resolved[@]}")
}

pyenv_versions=()
while [ "$#" -gt 0 ]; do
    case "$1" in
        --python)
            if [ "$#" -lt 2 ]; then
                echo "verify.sh: --python needs a version." >&2
                exit 2
            fi
            pyenv_versions+=("$2")
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "verify.sh: unknown argument '$1'." >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [ "${#pyenv_versions[@]}" -gt 0 ]; then
    resolve_pyenv_versions
fi

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

# Without --python the step runs once, on the interpreter .devenv selects.
run_on_pythons() {
    local name=$1
    shift

    if [ "${#pyenv_versions[@]}" -eq 0 ]; then
        run "${name}" "$@"
        return
    fi

    local version
    for version in "${pyenv_versions[@]}"; do
        run "${name} (python ${version})" env WEEWX_PYENV_VERSION="${version}" "$@"
    done
}

run_on_pythons checkenv "${TOOLS_DIR}/checkenv.sh"
run lint "${TOOLS_DIR}/lint.sh"
run actionlint "${TOOLS_DIR}/actionlint.sh"
run refs "${TOOLS_DIR}/refs.sh" --check
run configs "${TOOLS_DIR}/configs.sh" --check
run commonrepos "${TOOLS_DIR}/commonrepos.sh" --check
run_on_pythons alltests "${TOOLS_DIR}/alltests.sh"

if [ "${status}" -ne 0 ]; then
    echo "Failed:${failed}"
fi

exit "${status}"
