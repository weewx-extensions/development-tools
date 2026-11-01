#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Copy the shared mqttcommon module and its tests from the mqttcommon
#    repository into this repository, or with --check, report the ones that
#    differ.
#
#    The copies are shipped (install.py lists them), so they stay in the
#    repository; this only keeps them in step with the source of truth.
#
set -euo pipefail

# A sibling checkout of the mqttcommon repository.
SRC_DIR=${MQTTCOMMON_SRC:-../mqttcommon}
COMMON_FILES='bin/user/mqttcommon.py bin/user/tests/unit/test_mqttcommon.py'

check=0
if [ "${1:-}" == '--check' ]; then
    check=1
fi

# Extensions that do not vendor the module have nothing to do.
if [ ! -f bin/user/mqttcommon.py ]; then
    echo "bin/user/mqttcommon.py is not vendored here, skipping."
    exit 0
fi

if [ ! -d "${SRC_DIR}" ]; then
    # Only the check may skip: CI compares against the repository, so a
    # contributor without the checkout is not blocked. Copying cannot.
    if [ "${check}" == "1" ] && [ -z "${MQTTCOMMON_SRC:-}" ]; then
        echo "No ${SRC_DIR} checkout, skipping. Set MQTTCOMMON_SRC to check."
        exit 0
    fi
    echo "${SRC_DIR} does not exist. Set MQTTCOMMON_SRC to the mqttcommon checkout."
    exit 1
fi

status=0
for file in ${COMMON_FILES}; do
    if [ ! -f "${SRC_DIR}/${file}" ]; then
        echo "Missing ${SRC_DIR}/${file}"
        status=1
        continue
    fi

    if [ "${check}" == "1" ]; then
        if ! diff -u "${SRC_DIR}/${file}" "${file}"; then
            echo "${file} differs from ${SRC_DIR}/${file}"
            status=1
        fi
    else
        cp "${SRC_DIR}/${file}" "${file}"
        echo "Wrote ${file}"
    fi
done

exit "${status}"
