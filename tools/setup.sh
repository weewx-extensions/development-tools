#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Provision a development machine with the tree the tools expect: the
#    extension, fork and WeeWX repositories, the WeeWX releases, and the
#    weewx-data links that point at them.
#
#    Run it from $HOME, which every path in it is relative to. A second run
#    leaves the tree as it is; the two steps it does not own are commented out
#    below.
#
set -uo pipefail

# Where the tree is built. Both default to the layout the tools document, and
# both can be overridden in the environment, which is what lets a run be
# pointed at a scratch directory.
WEEWX_CODE_ROOT="${WEEWX_CODE_ROOT:-$HOME/weewx_code}"
WEEWX_DATA_DIR="${WEEWX_DATA_DIR:-$HOME/weewx-data}"

# The interpreter the final steps use.
PYTHON="${PYTHON:-python3}"

# EDIT THESE - the repositories this tree is built from, grouped by the
# directory they are cloned into, and the two that are worked on a branch other
# than the default. The clone destination is the URL's basename, which is the
# name `git clone` would give it.
ROOT_REPOS=(
    git@github.com:bellrichm/WeeWX-Extras
    git@github.com:bellrichm/configs
    richbell@rmbell.local:/home/richbell/git-repos/secrets
)
FORK_REPOS=(
    git@github.com:bellrichm/fuzzy-archer
    git@github.com:bellrichm/vds-weewx-v3-mem-extension
    git@github.com:bellrichm/weewx-belchertown
    git@github.com:bellrichm/weewx-celestial
    git@github.com:bellrichm/weewx-cmon
    git@github.com:bellrichm/weewx-loopdata
    git@github.com:bellrichm/weewx-nws
    git@github.com:bellrichm/weewx-skyfield
    git@github.com:bellrichm/weewx-wdc
    git@github.com:bellrichm/weewx-xaggs
)
EXTENSION_REPOS=(
    git@github.com:weewx-extensions/aqi-xtype
    git@github.com:weewx-extensions/development-tools
    git@github.com:weewx-extensions/jas
    git@github.com:weewx-extensions/healthchecks
    git@github.com:weewx-extensions/pushover
    git@github.com:weewx-extensions/test
)
MQTT_REPOS=(
    git@github.com:weewx-mqtt/mqttcommon
    git@github.com:weewx-mqtt/plugin-loopdata
    git@github.com:weewx-mqtt/publish
    git@github.com:weewx-mqtt/replicate
    git@github.com:weewx-mqtt/subscribe
)
BRANCHES=(
    "weewx-celestial mqtt"
    "weewx-skyfield file_location"
)

# The released WeeWX versions unpacked side by side, oldest and latest as the
# workflow matrix pins them, and where they come from.
WEEWX_VERSIONS=(5.5.2 5.0.0)
WEEWX_RELEASES_URL='https://weewx.com/downloads/released_versions'

# The extension modules linked into the station's bin/user, and the skins linked
# into its skins directory. Each entry is a path beneath WEEWX_CODE_ROOT, and the
# link takes the source's basename.
USER_MODULES=(
    weewx-extensions/aqi-xtype/bin/user/aqitype.py
    WeeWX-Extras/bin/user/backup.py
    forks/weewx-belchertown/bin/user/belchertown.py
    forks/weewx-celestial/bin/user/celestial.py
    forks/weewx-celestial/bin/user/celestial_page.py
    forks/weewx-celestial/bin/user/celestial_sky.py
    forks/weewx-cmon/bin/user/cmon.py
    weewx-extensions/healthchecks/bin/user/healthchecks.py
    forks/fuzzy-archer/bin/user/historygenerator.py
    weewx-extensions/jas/bin/user/jas.py
    weewx-extensions/jas/bin/user/jas_templates.py
    forks/fuzzy-archer/bin/user/jsonengine.py
    forks/fuzzy-archer/bin/user/largeimagegenerator.py
    forks/weewx-loopdata/bin/user/loopdata.py
    forks/vds-weewx-v3-mem-extension/bin/user/mem.py
    weewx-mqtt/publish/bin/user/mqttaggregatevalues.py
    weewx-mqtt/publish/bin/user/mqttarchivevalues.py
    weewx-mqtt/mqttcommon/bin/user/mqttcommon.py
    weewx-mqtt/publish/bin/user/mqttconfigha.py
    weewx-mqtt/publish/bin/user/mqtthaconfig.py
    weewx-mqtt/plugin-loopdata/bin/user/mqttloopdata.py
    weewx-mqtt/publish/bin/user/mqttmessagetracker.py
    weewx-mqtt/publish/bin/user/mqttpublish.py
    weewx-mqtt/replicate/bin/user/mqttreplicate.py
    weewx-mqtt/subscribe/bin/user/mqttsubscribe.py
    weewx-mqtt/publish/bin/user/mqtttracker.py
    weewx-extensions/pushover/bin/user/notify.py
    forks/weewx-nws/bin/user/nws.py
    WeeWX-Extras/bin/user/observationtime.py
    weewx-extensions/pushover/bin/user/pushover.py
    WeeWX-Extras/bin/user/replicatedb.py
    weewx-mqtt/replicate/bin/user/run_mqttreplicate.py
    WeeWX-Extras/bin/user/runreports.py
    WeeWX-Extras/bin/user/s3upload.py
    forks/fuzzy-archer/bin/user/sunevents.py
    forks/weewx-wdc/bin/user/weewx_wdc.py
    forks/weewx-skyfield/bin/user/wxskyfield.py
    forks/weewx-skyfield/bin/user/wxskyfield_de421.bsp
    forks/weewx-skyfield/bin/user/wxskyfield_lines.dat
    forks/weewx-skyfield/bin/user/wxskyfield_sky.py
    forks/weewx-skyfield/bin/user/wxskyfield_stars.dat.gz
    forks/weewx-xaggs/bin/user/xaggs.py
)
SKINS=(
    forks/weewx-belchertown/skins/Belchertown
    forks/fuzzy-archer/skins/Bootstrap
    forks/weewx-celestial/skins/Celestial
    forks/weewx-loopdata/skins/LoopData
    forks/weewx-celestial/skins/MQTTCelestial
    weewx-mqtt/plugin-loopdata/skins/MQTTLoopData
    WeeWX-Extras/skins/Production
    forks/weewx-loopdata/skins/ScriptData
    forks/weewx-skyfield/skins/Skyfield
    weewx-extensions/aqi-xtype/skins/aqitype
    forks/weewx-cmon/skins/cmon
    WeeWX-Extras/skins/develop
    weewx-extensions/healthchecks/skins/healthchecks
    weewx-extensions/jas/skins/jas
    forks/vds-weewx-v3-mem-extension/skins/mem
    forks/weewx-nws/skins/nws
    WeeWX-Extras/skins/s3
    forks/weewx-wdc/skins/weewx-wdc
)

usage() {
    cat <<'EOF'
Usage: setup.sh [--dry-run]

Provision the development tree under $HOME: clone the repositories, unpack the
WeeWX releases, and link the extension modules and skins into weewx-data.

Run it from $HOME.

  --dry-run   Say what would be done and change nothing.
EOF
}

# --dry-run is threaded through the helpers, so no action runs for real.
dry_run=0
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --dry-run)
            dry_run=1
            ;;
        *)
            echo "setup.sh: unknown argument '$1'." >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

# Every action reports one of create, skip or error, so a run says what it did
# and a re-run after fixing one problem resumes where the broken run stopped.
# The counts are summed at the end, and any error makes the script exit non-zero.
created=0
skipped=0
errors=0

fail() {
    echo "  error   $*" >&2
    errors=$((errors + 1))
}

skip() {
    echo "  skip    $*"
    skipped=$((skipped + 1))
}

# A create that a dry run must report without doing.
would() {
    echo "  create  $*"
    created=$((created + 1))
}

# Run a command, or with --dry-run report the command that would have run.
perform() {
    local description=$1
    shift

    if [ "${dry_run}" -eq 1 ]; then
        would "${description}"
        return 0
    fi
    if "$@"; then
        echo "  create  ${description}"
        created=$((created + 1))
    else
        fail "${description}"
    fi
}

# mkdir -p is idempotent on its own; this adds the reporting that everything
# else has, so a second run does not look like a no-op.
mkdir_p() {
    local dir=$1

    if [ -d "${dir}" ]; then
        skip "${dir}"
        return 0
    fi
    perform "${dir}" mkdir -p "${dir}"
}

# Clone a repository unless it is already checked out. A directory that is not a
# git checkout is an error rather than something to clone over, and a clone with
# a different origin is reported but left alone: the remote may have been
# swapped deliberately. The `.git` suffix is optional in a remote URL, so it is
# ignored when the two are compared.
clone() {
    local url=$1
    local dir=$2
    local origin

    if [ -e "${dir}" ]; then
        if [ ! -d "${dir}/.git" ]; then
            fail "${dir} exists and is not a git checkout"
            return 1
        fi
        origin=$(git -C "${dir}" remote get-url origin 2>/dev/null)
        if [ -n "${origin}" ] && [ "${origin%.git}" != "${url%.git}" ]; then
            echo "  warn    ${dir} has origin ${origin}, not ${url}"
        fi
        skip "${dir}"
        return 0
    fi
    perform "${dir}" git clone --quiet "${url}" "${dir}"
}

# Put a clone on the branch it is worked on, without ever discarding local work.
checkout_branch() {
    local dir=$1
    local branch=$2
    local current

    if [ ! -d "${dir}/.git" ]; then
        # A dry run reported a clone that has not happened, so the checkout it
        # would need cannot be inspected.
        if [ "${dry_run}" -eq 1 ]; then
            would "${dir} on ${branch}"
            return 0
        fi
        fail "${dir} is not a git checkout, cannot switch to ${branch}"
        return 1
    fi
    current=$(git -C "${dir}" rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ "${current}" = "${branch}" ]; then
        skip "${dir} is on ${branch}"
        return 0
    fi
    if [ -n "$(git -C "${dir}" status --porcelain 2>/dev/null)" ]; then
        fail "${dir} has local changes, left on ${current} rather than ${branch}"
        return 1
    fi
    perform "${dir} on ${branch}" git -C "${dir}" checkout "${branch}"
}

# Clone a group of repositories into one directory.
clone_into() {
    local dir=$1
    local url

    shift
    mkdir_p "${dir}"
    for url in "$@"; do
        clone "${url}" "${dir}/$(basename "${url}")"
    done
}

# Check out the BRANCHES list in the directory those repositories live in.
checkout_branches() {
    local dir=$1
    local entry

    if [ "${#BRANCHES[@]}" -eq 0 ]; then
        return 0
    fi
    for entry in "${BRANCHES[@]}"; do
        checkout_branch "${dir}/${entry%% *}" "${entry#* }"
    done
}

# Download one release and unpack it next to the others. The tarball is dropped
# whether or not the unpack worked, so a failure leaves no half-download behind.
download_release() {
    local version=$1
    local releases="${WEEWX_CODE_ROOT}/weewx-releases"
    local tarball="${releases}/weewx-${version}.tgz"

    if ! curl -fsSL -o "${tarball}" "${WEEWX_RELEASES_URL}/weewx-${version}.tgz"; then
        rm -f "${tarball}"
        return 1
    fi
    if ! tar -xzf "${tarball}" -C "${releases}"; then
        rm -f "${tarball}"
        return 1
    fi
    rm -f "${tarball}"
}

# curl rather than wget: macOS does not ship wget.
fetch_releases() {
    local version

    mkdir_p "${WEEWX_CODE_ROOT}/weewx-releases"
    for version in "${WEEWX_VERSIONS[@]}"; do
        if [ -d "${WEEWX_CODE_ROOT}/weewx-releases/weewx-${version}" ]; then
            skip "${WEEWX_CODE_ROOT}/weewx-releases/weewx-${version}"
            continue
        fi
        perform "${WEEWX_CODE_ROOT}/weewx-releases/weewx-${version}" \
            download_release "${version}"
    done
}

# Point DIR/NAME at TARGET. A link that is already there is repaired, never
# ignored; a real file is an error, because the script does not delete what it
# did not create.
link() {
    local target=$1
    local dir=$2
    local name=$3
    local dest="${dir}/${name}"
    local current

    # A dry run has only reported the clones and the station, so what they would
    # have created cannot be inspected.
    if [ ! -e "${target}" ] || [ ! -d "${dir}" ]; then
        if [ "${dry_run}" -eq 1 ]; then
            would "${dest} -> ${target}"
            return 0
        fi
        if [ ! -e "${target}" ]; then
            fail "${dest} -> ${target}: target does not exist"
        else
            fail "${dir} does not exist, cannot link ${name} into it"
        fi
        return 1
    fi

    if [ -L "${dest}" ]; then
        current=$(readlink "${dest}")
        if [ "${current}" = "${target}" ]; then
            skip "${dest} -> ${target}"
            return 0
        fi
        perform "${dest} -> ${target} (was ${current})" ln -sfn "${target}" "${dest}"
        return 0
    fi
    if [ -e "${dest}" ]; then
        fail "${dest} exists and is not a link"
        return 1
    fi
    perform "${dest} -> ${target}" ln -sfn "${target}" "${dest}"
}

# Link a whole list of sources into one directory, each under its own name.
link_all() {
    local dir=$1
    local source

    shift
    for source in "$@"; do
        link "${WEEWX_CODE_ROOT}/${source}" "${dir}" "$(basename "${source}")"
    done
}

if [ "${dry_run}" -eq 1 ]; then
    echo "Dry run: nothing will be changed."
fi

clone_into "${WEEWX_CODE_ROOT}" "${ROOT_REPOS[@]}"
clone_into "${WEEWX_CODE_ROOT}/forks" "${FORK_REPOS[@]}"
checkout_branches "${WEEWX_CODE_ROOT}/forks"
clone_into "${WEEWX_CODE_ROOT}/weewx-extensions" "${EXTENSION_REPOS[@]}"
clone_into "${WEEWX_CODE_ROOT}/weewx-mqtt" "${MQTT_REPOS[@]}"

fetch_releases
clone git@github.com:weewx/weewx "${WEEWX_CODE_ROOT}/weewx-releases/weewx-clone"
clone git@github.com:bellrichm/weewx "${WEEWX_CODE_ROOT}/weewx-releases/weewx-fork"

# The two aliases the tools and the extensions expect: weewx-mqtt/weewx-fork is
# the fork, weewx-mqtt/weewx is what an extension looks up, and the link in the
# current directory is the checkout everything else is run from.
link "${WEEWX_CODE_ROOT}/weewx-releases/weewx-fork" "${WEEWX_CODE_ROOT}/weewx-mqtt" weewx-fork
link "${WEEWX_CODE_ROOT}/weewx-mqtt/weewx-fork" "${WEEWX_CODE_ROOT}/weewx-mqtt" weewx
link "${WEEWX_CODE_ROOT}/weewx-releases/weewx-fork" "${PWD}" weewx

# The station has to exist before anything can be linked into it, and an
# existing one is left alone: creating it again would discard its configuration.
if [ -e "${WEEWX_DATA_DIR}/weewx.conf" ]; then
    skip "${WEEWX_DATA_DIR}"
else
    perform "${WEEWX_DATA_DIR}" "${PYTHON}" "${PWD}/weewx/src/weectl.py" \
        station create "${WEEWX_DATA_DIR}" --no-prompt
fi

# Where the daemon keeps its pid and sockets.
mkdir_p "${WEEWX_DATA_DIR}/run"

link_all "${WEEWX_DATA_DIR}/bin/user" "${USER_MODULES[@]}"
link_all "${WEEWX_DATA_DIR}/skins" "${SKINS[@]}"

# Two steps this script does not own: assembling weewx.conf from the configs
# repository, and listing the WeeWX versions. Run them by hand until they have a
# tracked home.
# "${WEEWX_CODE_ROOT}/configs/extensions/development-config.sh"
# "${WEEWX_CODE_ROOT}/weewx-extensions/development-tools/tools/listVersions.py"

# The dependencies belong to an interpreter, and each pyenv version has its own,
# so they are installed by hand rather than from here:
# pyenv install 3.15
# pyenv global 3.15
# pip install configobj
# pip install ct3
# pip install Pillow
# pip install paho.mqtt
# pip install jplephem
# pip install skyfield
# pip install boto3 six   # for the AWS-S3 report's upload generator

echo
if [ "${dry_run}" -eq 1 ]; then
    echo "Dry run: ${created} would be created, ${skipped} skipped, ${errors} errors."
elif [ "${errors}" -ne 0 ]; then
    echo "Failed: ${created} created, ${skipped} skipped, ${errors} errors." >&2
else
    echo "Done: ${created} created, ${skipped} skipped."
fi

if [ "${errors}" -ne 0 ]; then
    exit 1
fi

# The daemon is started by whatever supervises the station on this machine, not
# by the script that provisions it.
# ${PYTHON} ${PWD}/weewx/src/weewxd.py --config "${WEEWX_DATA_DIR}/weewx.conf"
