#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Copy the shared config files from development-tools/config into this
#    repository, or with --check, report the ones that differ.
#
set -euo pipefail

CONFIG_DIR="$(dirname "$(readlink -f "$0")")/../config"
CONFIGS='.pylintrc .pylintrc-tests .flake8 .coveragerc .codacy.yaml requirements.txt'

check=0
if [ "${1:-}" == '--check' ]; then
    check=1
fi

status=0
for config in ${CONFIGS}; do
    if [ ! -f "${CONFIG_DIR}/${config}" ]; then
        echo "Missing ${CONFIG_DIR}/${config}"
        status=1
        continue
    fi

    if [ "${check}" == "1" ]; then
        # The workflow skips a config the repository does not carry; mirror that
        # so a local run of verify.sh agrees with CI.
        if [ ! -f "${config}" ]; then
            echo "${config} is not in this repository, skipping the check."
            continue
        fi

        if ! diff -u "${CONFIG_DIR}/${config}" "${config}"; then
            echo "${config} differs from ${CONFIG_DIR}/${config}"
            status=1
        fi
    else
        cp "${CONFIG_DIR}/${config}" "${config}"
        echo "Wrote ${config}"
    fi
done

exit "${status}"
