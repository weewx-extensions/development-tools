#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Lint .github/workflows with actionlint, downloading the pinned release
#    into tools/ the first time it is needed.
#
#    The download is a cache, not a vendored file, so it stays out of the
#    repository (see .gitignore) and an actionlint already on PATH wins.
#
set -euo pipefail

TOOLS_DIR="$(cd "$(dirname "$0")" && pwd -P)"
ACTIONLINT="${TOOLS_DIR}/actionlint"

# Pinned so the local check matches CI. Override to try another release.
VERSION=${ACTIONLINT_VERSION:-1.7.12}

version_of() {
    "$1" --version 2>/dev/null | head -1
}

download() {
    local os arch url tmp_dir

    case "$(uname -s)" in
        Linux) os=linux ;;
        Darwin) os=darwin ;;
        *)
            echo "actionlint: no release for $(uname -s)"
            return 1
            ;;
    esac

    case "$(uname -m)" in
        x86_64|amd64) arch=amd64 ;;
        arm64|aarch64) arch=arm64 ;;
        *)
            echo "actionlint: no release for $(uname -m)"
            return 1
            ;;
    esac

    url="https://github.com/rhysd/actionlint/releases/download/v${VERSION}/actionlint_${VERSION}_${os}_${arch}.tar.gz"
    tmp_dir="$(mktemp -d)"
    # Expanded now, so the trap still has the path after the function returns.
    # shellcheck disable=SC2064
    trap "rm -rf '${tmp_dir}'" EXIT

    echo "Downloading ${url}"
    if ! curl -fsSL "${url}" -o "${tmp_dir}/actionlint.tar.gz"; then
        echo "actionlint: download failed"
        return 1
    fi

    tar -xzf "${tmp_dir}/actionlint.tar.gz" -C "${tmp_dir}" actionlint
    mv "${tmp_dir}/actionlint" "${ACTIONLINT}"
    chmod +x "${ACTIONLINT}"

    rm -rf "${tmp_dir}"
    trap - EXIT
}

# The cached download wins when it holds the pinned release; otherwise an
# actionlint on PATH stands in, and only failing that is one fetched.
if [ -x "${ACTIONLINT}" ] && [ "$(version_of "${ACTIONLINT}")" == "${VERSION}" ]; then
    :
elif [ ! -x "${ACTIONLINT}" ] && command -v actionlint >/dev/null 2>&1; then
    ACTIONLINT=$(command -v actionlint)
elif ! download; then
    echo "actionlint is not available, skipping the workflow lint."
    exit 0
fi

if [ ! -d .github/workflows ]; then
    echo "No .github/workflows here, skipping the workflow lint."
    exit 0
fi

# With no arguments actionlint finds .github/workflows itself.
exec "${ACTIONLINT}" "$@"
