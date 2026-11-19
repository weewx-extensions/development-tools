#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
# Install a Python version with pyenv, and the pip dependencies the tools and
# extensions need into it. The dependencies belong to an interpreter, and each
# pyenv version has its own, so they are installed per version rather than once
# for the machine.

set -uo pipefail

usage() {
    cat <<'EOF'
Usage: installPython.sh <python-version>

Install the named Python version with pyenv, and the pip dependencies the tools
and extensions need into it.

Run it from $HOME.

  <python-version>   A pyenv version, for example 3.15.
EOF
}

if [ "$#" -eq 0 ] || [ "$#" -gt 1 ]; then
    usage >&2
    exit 2
fi

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 0
fi

python_version=$1

if ! command -v pyenv >/dev/null 2>&1; then
    echo "  error   pyenv is not installed." >&2
    exit 1
fi

echo "Building Python ${python_version} with pyenv."
if ! bash "$(dirname "$0")/build-pythons.sh" "${python_version}"; then
    echo "  error   building Python ${python_version} failed." >&2
    exit 1
fi

echo "Setting ${python_version} as the global pyenv version."
if ! pyenv global "${python_version}"; then
    echo "  error   pyenv global ${python_version} failed." >&2
    exit 1
fi

echo "Installing pip dependencies into ${python_version}."
if ! python -m pip install configobj ct3 Pillow paho-mqtt jplephem skyfield boto3 six; then
    echo "  error   pip install failed for ${python_version}." >&2
    exit 1
fi

echo "Done."
