#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
# Rebuild pyenv CPython versions against Homebrew's SQLite instead of Apple's.
#
# Why: opening *any* SQLite database in a forked child segfaults when Python's _sqlite3
# extension links Apple's /usr/lib/libsqlite3.dylib:
#
#   EXC_BAD_ACCESS (SIGSEGV) in libsqlite3.dylib -> openDatabase
#     <- _sqlite3.cpython-3xx-darwin.so -> pysqlite_connection_init
#
# Observed with, on 2026-11-18. The failing library is the OS one, so treat any macOS that
# ships that libsqlite3 as a candidate rather than assuming it is peculiar to this machine:
#
#   macOS 27.2.1 (build 26B8132, Darwin 27.2.0), arm64, Mac17,12
#   Apple libsqlite3 3.54.0 - in the dyld shared cache, so /usr/lib/libsqlite3.dylib is not
#     a file on disk; recorded as current version 408.0.0, and /usr/bin/sqlite3 --version
#     reports the same 3.54.0 build ending in "aapl"
#   Homebrew sqlite 3.54.1 at /opt/homebrew/opt/sqlite, which is what this script links to
#   CPython 3.9.13, 3.10.22, 3.14.10, 3.15.2 (pyenv) and 3.9.6 (/usr/bin/python3) all failed
#   Crash reports land in ~/Library/Logs/DiagnosticReports/python3.*.ips
#
# Binding it to Homebrew's keg (3.54.1) makes the same fork survive. The standalone
# reproducer is sqlite-fork-repro.py next to this script.
#
# A plain `pyenv install -f` silently undoes the fix: CPython's configure asks pkg-config
# for `sqlite3 >= 3.15.2`, and on a Homebrew machine that resolves to Homebrew's shim for the
# macOS SDK (/opt/homebrew/Library/Homebrew/os/mac/pkgconfig/<ver>/sqlite3.pc), which
# points at /usr/lib. `sqlite` is keg-only, so it is not on the default search path
# either. The three variables below are what make the keg win.
#
# Usage:
#   build-pythons.sh                 # rebuild and verify the oldest and newest supported versions
#   build-pythons.sh 3.14.10         # just that version
#   build-pythons.sh --verify-only   # check installed versions, change nothing
#
# A version this script does not know is built with pyenv's own OpenSSL preference list, because
# it cannot know what that interpreter "should" be using. verify() then prints the OpenSSL it got
# but asserts nothing; to pin and check one, add it to openssl_formula() (which Homebrew formula
# to build against) and expected_openssl() (what to assert). That pair is the per-version work.
#
# Every entry in both is openssl@3, which is also python-build's own first choice for each of
# them (its per-version definitions call prefer_openssl3 or prefer_openssl3_to_4). The pin is
# therefore a record of the intended state rather than a correction, and it earns its keep by
# making verify() assert: a bare `pyenv install -f` asks python-build again, and if openssl@3 is
# ever missing, its preference list slides to bare `openssl` (the linked openssl@4 keg) instead
# of failing. The pinned build then fails the assertion rather than changing the TLS library
# quietly. 3.15.2 sat on 4.1.0 for exactly that reason - openssl@3 was not installed when it was
# originally built - so it, too, is pinned to 3 here.
#
# This one is macOS-only: it needs the Homebrew sqlite keg and `otool`. The rest of the tools
# run on Linux as well.
#
set -uo pipefail

SQLITE_PREFIX="${SQLITE_PREFIX:-/opt/homebrew/opt/sqlite}"
MAKE_OPTS="${MAKE_OPTS:--j$(sysctl -n hw.ncpu)}"
# What a bare `build-pythons.sh` (or `--verify-only`) covers: the ends of the supported range,
# which are the versions a compatibility check turns on. It restricts nothing - naming a version
# overrides the list - and it changes nothing outside this script: not pyenv's global version,
# not which interpreter anything else is launched with.
#
# The versions come from supported-pythons (through versions.sh), so a new supported version
# needs no entry here. Add one to openssl_formula() and expected_openssl() only to pin and
# assert its OpenSSL.
TOOLS_DIR="$(cd "$(dirname "$0")" && pwd -P)"
. "${TOOLS_DIR}/versions.sh"
DEFAULT_VERSIONS=("${WEEWX_PYTHON_OLDEST}" "${WEEWX_PYTHON_LATEST}")

# The description above, without the copyright block and without depending on line numbers.
usage() {
    awk '/^# Rebuild pyenv/ { shown = 1 }
         shown && /^#/ { sub(/^# ?/, ""); print; next }
         shown { exit }' "$0"
}

# Which Homebrew OpenSSL each interpreter was built with.
#
# This is the knob that works: python-build reads PYTHON_BUILD_HOMEBREW_OPENSSL_FORMULA, picks
# the first installed formula from it, and then does the work that makes the choice stick - it
# passes --with-openssl=<prefix> *and* prepends -I<prefix>/include, -L<prefix>/lib,
# -Wl,-rpath,<prefix>/lib and <prefix>/lib/pkgconfig to the build flags.
#
# Do not pin this with PYTHON_CONFIGURE_OPTS="--with-openssl=...": python-build skips its own
# detection whenever it sees --with-openssl (configured_with_openssl || use_homebrew_openssl),
# so none of that prepending happens, and --with-openssl only *appends* flags. On a machine
# where the unversioned `openssl` formula (openssl@4) is linked into /opt/homebrew and its
# openssl.pc is on the default pkg-config path, the build then links openssl@4 whatever was
# asked for: pinning openssl@3 that way produced OpenSSL 4.1.0, silently.
#
# Pass nothing to keep pyenv's own preference list (it starts with openssl@3).
openssl_formula() {
    case "$1" in
        3.9.13|3.10.22|3.14.10|3.15.2) echo openssl@3 ;;
        *) : ;;
    esac
}

# The OpenSSL major each version is expected to report, so a drift in pyenv's detection
# is caught rather than discovered later. A version with no entry here is the one case
# verify() cannot judge: it prints the OpenSSL it found and asserts nothing.
expected_openssl() {
    case "$1" in
        3.9.13|3.10.22|3.14.10|3.15.2) echo 3 ;;
        *) : ;;
    esac
}

# Fail before spending five minutes on a build that resolves to Apple's dylib.
preflight() {
    local libs libdir

    if [ ! -f "${SQLITE_PREFIX}/lib/libsqlite3.dylib" ]; then
        echo "build-pythons.sh: no libsqlite3.dylib under ${SQLITE_PREFIX}; brew install sqlite" >&2
        return 1
    fi
    if [ ! -f "${SQLITE_PREFIX}/lib/pkgconfig/sqlite3.pc" ]; then
        echo "build-pythons.sh: no sqlite3.pc under ${SQLITE_PREFIX}/lib/pkgconfig" >&2
        return 1
    fi

    libdir="$(PKG_CONFIG_PATH="${SQLITE_PREFIX}/lib/pkgconfig" pkg-config --variable=libdir sqlite3)"
    libs="$(PKG_CONFIG_PATH="${SQLITE_PREFIX}/lib/pkgconfig" pkg-config --libs sqlite3)"
    case "${libdir}|${libs}" in
        "${SQLITE_PREFIX}/lib|"*"-L${SQLITE_PREFIX}/lib"*) ;;
        *)
            echo "build-pythons.sh: pkg-config still resolves sqlite3 to ${libdir}" >&2
            echo "                 expected ${SQLITE_PREFIX}/lib, with -L${SQLITE_PREFIX}/lib" >&2
            return 1
            ;;
    esac

    echo "sqlite keg: $(PKG_CONFIG_PATH="${SQLITE_PREFIX}/lib/pkgconfig" pkg-config --modversion sqlite3) at ${SQLITE_PREFIX}/lib"
}

build() {
    local version=$1
    local formula

    formula="$(openssl_formula "${version}")"
    echo "== building ${version} (openssl formula: ${formula:-pyenv default})"

    if [ -n "${formula}" ]; then
        env PKG_CONFIG_PATH="${SQLITE_PREFIX}/lib/pkgconfig" \
            CPPFLAGS="-I${SQLITE_PREFIX}/include" \
            LDFLAGS="-L${SQLITE_PREFIX}/lib" \
            MAKE_OPTS="${MAKE_OPTS}" \
            PYTHON_BUILD_HOMEBREW_OPENSSL_FORMULA="${formula}" \
            pyenv install -f "${version}"
    else
        env PKG_CONFIG_PATH="${SQLITE_PREFIX}/lib/pkgconfig" \
            CPPFLAGS="-I${SQLITE_PREFIX}/include" \
            LDFLAGS="-L${SQLITE_PREFIX}/lib" \
            MAKE_OPTS="${MAKE_OPTS}" \
            pyenv install -f "${version}"
    fi
}

verify() {
    local version=$1
    local prefix python extension linked expected major

    if ! prefix="$(pyenv prefix "${version}" 2>/dev/null)"; then
        echo "build-pythons.sh: python ${version} is not installed" >&2
        return 1
    fi
    python="${prefix}/bin/python"
    extension="$("${python}" -c 'import _sqlite3; print(_sqlite3.__file__)')" || return 1
    linked="$(otool -L "${extension}" | sed -n 2p | awk '{print $1}')"
    expected="$(PKG_CONFIG_PATH="${SQLITE_PREFIX}/lib/pkgconfig" pkg-config --modversion sqlite3)"
    major="$(expected_openssl "${version}")"

    if [ "${linked}" != "${SQLITE_PREFIX}/lib/libsqlite3.dylib" ]; then
        echo "build-pythons.sh: ${version} links ${linked}, not the Homebrew keg" >&2
        return 1
    fi

    # sqlite3.sqlite_version is the library's own version; if it matches the keg it is
    # the keg that is actually loaded at runtime, not just recorded in the load command.
    if ! "${python}" - "${expected}" "${major}" <<'PY'
import sqlite3, ssl, sys
expected_sqlite, expected_ssl_major = sys.argv[1], sys.argv[2]
if sqlite3.sqlite_version != expected_sqlite:
    sys.exit(f"error: loaded sqlite3 {sqlite3.sqlite_version}, keg is {expected_sqlite}")
print("sqlite", sqlite3.sqlite_version)
print("ssl", ssl.OPENSSL_VERSION)
if expected_ssl_major and not ssl.OPENSSL_VERSION.startswith(f"OpenSSL {expected_ssl_major}."):
    sys.exit(f"error: ssl is {ssl.OPENSSL_VERSION}, expected OpenSSL {expected_ssl_major}.x")
PY
    then
        return 1
    fi

    if [ -z "${major}" ]; then
        echo "ok: ${version} -> ${linked} (openssl printed but not checked: no expected_openssl entry)"
        return 0
    fi
    echo "ok: ${version} -> ${linked}"
}

main() {
    local verify_only=0
    local version
    local failed=0
    local versions=()

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                usage
                return 0
                ;;
            --verify-only)
                verify_only=1
                ;;
            -*)
                echo "build-pythons.sh: unknown option '$1'." >&2
                usage >&2
                return 2
                ;;
            *)
                versions+=("$1")
                ;;
        esac
        shift
    done
    if [ "${#versions[@]}" -eq 0 ]; then
        versions=("${DEFAULT_VERSIONS[@]}")
    fi

    if [ "$(uname -s)" != 'Darwin' ]; then
        echo "build-pythons.sh: this script is macOS only (Homebrew sqlite keg, otool)." >&2
        return 2
    fi

    preflight || return 1

    for version in "${versions[@]}"; do
        if [ "${verify_only}" -eq 0 ]; then
            if ! build "${version}"; then
                failed=1
                continue
            fi
        fi
        verify "${version}" || failed=1
    done

    if [ "${failed}" -ne 0 ]; then
        echo "FAILED" >&2
        return 1
    fi
    echo "all versions verified"
    echo "next: sqlite-fork-repro.py with each interpreter, and restart weewxd if it uses one"
}

main "$@"
