#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Point this repository's reusable workflow refs at the current release, or
#    with --check, report the ones that have gone stale.
#
#    analyze-test, analyze-test-matrix, perform-analyze-test, and fetch follow
#    the development-tools major version tag; stale and versioning follow
#    latest. The major version is this repository's own config-ref default, so
#    a release moves the refs the same way it moves the config files.
#
set -uo pipefail

TOOLS_DIR="$(dirname "$(readlink -f "$0")")"
DEVTOOLS_DIR="$(dirname "${TOOLS_DIR}")"

check=0
if [ "${1:-}" == '--check' ]; then
    check=1
fi

if [ ! -d .github/workflows ]; then
    echo "No .github/workflows here, nothing to do."
    exit 0
fi

if [ "$(pwd -P)" == "$(cd "${DEVTOOLS_DIR}" && pwd -P)" ]; then
    echo "This is development-tools itself; its own workflows test the published refs."
    exit 0
fi

MAJOR=$(awk '/^ *config-ref:/ { found = 1 }
             found && /^ *default:/ { gsub(/.*default: *|'\''/, ""); print; exit }' \
        "${DEVTOOLS_DIR}/.github/workflows/analyze-test.yml")
if [ -z "${MAJOR}" ]; then
    echo "Could not read the config-ref default from ${DEVTOOLS_DIR}"
    exit 1
fi

WORKFLOW_PATH='weewx-extensions/development-tools/.github/workflows/'
USES_RE="uses:[[:space:]]+${WORKFLOW_PATH//./\\.}"

expected_ref() {
    case "$1" in
        analyze-test|analyze-test-matrix|perform-analyze-test|fetch) echo "${MAJOR}" ;;
        stale|versioning) echo 'latest' ;;
        *) echo '' ;;
    esac
}

status=0
for workflow in .github/workflows/*.yml; do
    [ -f "${workflow}" ] || continue

    # local-*, master-*, and the test repository's harnesses deliberately
    # float; only the workflows that drive CI have a current ref.
    case "${workflow##*/}" in
        analyze-test.yml|analyze-test-matrix.yml|run-analyze-test.yml|run-analyze-test-matrix.yml|fetch.yml|run-fetch.yml) : ;;
        *) continue ;;
    esac

    while IFS= read -r match; do
        lineno=${match%%:*}
        line=${match#*:}

        # Skip the commented alternatives the templates carry.
        case "${line#"${line%%[![:space:]]*}"}" in
            '#'*) continue ;;
        esac

        usage=${line#*"${WORKFLOW_PATH}"}
        name=${usage%%@*}
        name=${name%.yml}
        ref=${usage#*@}
        ref=${ref%%[[:space:]]*}
        expected=$(expected_ref "${name}")
        if [ -z "${expected}" ] || [ "${ref}" == "${expected}" ]; then
            continue
        fi

        if [ "${check}" == "1" ]; then
            echo "${workflow}:${lineno}: ${name}.yml@${ref} should be @${expected}"
            status=1
        else
            sed -i "${lineno}s|${name}\.yml@${ref}|${name}.yml@${expected}|" "${workflow}"
            echo "${workflow}:${lineno}: ${name}.yml@${ref} -> @${expected}"
        fi
    done < <(grep -nE "${USES_RE}" "${workflow}")
done

exit "${status}"
