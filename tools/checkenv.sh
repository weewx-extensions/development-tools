#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Check that what the CI installs is installed here: weewx, paho, the test
#    and lint tools, and the integration suite's broker. Reports every miss.
#
set -uo pipefail

. "$(dirname "$(readlink -f "$0")")/common.sh"

# The versions CI pins, read from this repository's workflow.
workflow=$(ls .github/workflows/*analyze-test*.yml 2>/dev/null | head -1)
expected_weewx=''
expected_paho=''
if [ -n "${workflow}" ]; then
    expected_weewx=$(sed -n "s/.*latest-weewx-version: *'\([^']*\)'.*/\1/p" "${workflow}" | head -1)
    expected_paho=$(sed -n "s/.*pip-list: *'\(paho-mqtt[^']*\)'.*/\1/p" "${workflow}" | head -1)
fi

errors=0
ok() {
    echo "  ok      $*"
}
fail() {
    echo "  MISSING $*"
    errors=$((errors + 1))
}
note() {
    echo "  note    $*"
}

echo "Checking ${WEEWX_MODULE_NAME:-the extension}"

python_version=$(python3 -c 'import platform; print(platform.python_version())' 2>/dev/null)
if [ -n "${python_version}" ]; then
    ok "python ${python_version}"
else
    fail "python3"
fi

weewx_info=$(python3 -c 'import weewx; print(weewx.__version__, weewx.__file__)' 2>/dev/null)
weewx_version=''
if [ -n "${weewx_info}" ]; then
    weewx_version=${weewx_info%% *}
    ok "weewx ${weewx_info}"
    if [ -n "${expected_weewx}" ] && [ "${weewx_version}" != "${expected_weewx}" ]; then
        note "not the workflow's ${expected_weewx}"
    fi
else
    fail "weewx (pip install weewx, or point WEEWX_PYTHONPATH at a checkout)"
fi

paho_version=$(python3 -c 'import importlib.metadata as metadata; print(metadata.version("paho-mqtt"))' 2>/dev/null)
if [ -n "${paho_version}" ]; then
    ok "paho-mqtt ${paho_version}"
    if [[ "${expected_paho}" == *'=='* ]] && [ "${paho_version}" != "${expected_paho#*==}" ]; then
        note "not the workflow's ${expected_paho}"
    fi
else
    fail "paho-mqtt"
fi

if command -v weectl >/dev/null 2>&1; then
    ok "weectl"
else
    note "weectl is not on PATH (it comes with an installed weewx)"
fi

modules='configobj coverage flake8 flake8_cognitive_complexity mock pylint pytest'
if [ "${WEEWX_HTML}" == "1" ]; then
    modules="${modules} pytest_html"
fi
for module in ${modules}; do
    if python3 -c "import ${module}" >/dev/null 2>&1; then
        ok "${module}"
    else
        fail "${module}"
    fi
done

IFS=: read -r -a python_paths <<< "${WEEWX_PYTHONPATH}"
for path in "${python_paths[@]}"; do
    expanded=${path/#\~/${HOME}}
    if [ -d "${expanded}" ]; then
        ok "path ${path}"
    else
        fail "path ${path}"
    fi
done

if [[ " ${WEEWX_TEST_SUITES} " == *' integ '* ]]; then
    if (exec 3<>/dev/tcp/127.0.0.1/1883) 2>/dev/null; then
        ok "mosquitto on 127.0.0.1:1883"
    else
        fail "mosquitto on 127.0.0.1:1883 (the integration tests need a broker)"
    fi
fi

if [ "${errors}" -gt 0 ]; then
    echo "${errors} check(s) failed."
    exit 1
fi

echo "All checks passed."
