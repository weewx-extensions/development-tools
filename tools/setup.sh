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
#    Run it from $HOME, which every path in it is relative to. It is a proof of
#    concept and not yet re-runnable: the clones and links below still fail on a
#    second run.
#
set -uo pipefail

# Where the tree is built. Both default to the layout the tools document, and
# both can be overridden in the environment, which is what lets a run be
# pointed at a scratch directory.
WEEWX_CODE_ROOT="${WEEWX_CODE_ROOT:-$HOME/weewx_code}"
WEEWX_DATA_DIR="${WEEWX_DATA_DIR:-$HOME/weewx-data}"

# The interpreter the final steps use.
PYTHON="${PYTHON:-python3}"

usage() {
    cat <<'EOF'
Usage: setup.sh [--dry-run]

Provision the development tree under $HOME: clone the repositories, unpack the
WeeWX releases, and link the extension modules and skins into weewx-data.

Run it from $HOME.

  --dry-run   Say what would be done and change nothing.
EOF
}

# --dry-run covers the mkdirs below for now; the clones, downloads and links
# join it as each is converted to one of these helpers.
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

# Run a command, or with --dry-run report the command that would have run.
perform() {
    local description=$1
    shift

    if [ "${dry_run}" -eq 1 ]; then
        echo "  create  ${description}"
        created=$((created + 1))
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

if [ "${dry_run}" -eq 1 ]; then
    echo "Dry run: nothing will be changed."
fi

mkdir_p "${WEEWX_CODE_ROOT}"



git clone git@github.com:bellrichm/WeeWX-Extras "${WEEWX_CODE_ROOT}/WeeWX-Extras"
git clone git@github.com:bellrichm/configs "${WEEWX_CODE_ROOT}/configs"
git clone git://rmbell.local/secrets "${WEEWX_CODE_ROOT}/secrets"

mkdir_p "${WEEWX_CODE_ROOT}/forks"
git clone git@github.com:bellrichm/fuzzy-archer "${WEEWX_CODE_ROOT}/forks/fuzzy-archer"
git clone git@github.com:bellrichm/vds-weewx-v3-mem-extension "${WEEWX_CODE_ROOT}/forks/vds-weewx-v3-mem-extension"
git clone git@github.com:bellrichm/weewx-belchertown "${WEEWX_CODE_ROOT}/forks/weewx-belchertown"
git clone git@github.com:bellrichm/weewx-celestial "${WEEWX_CODE_ROOT}/forks/weewx-celestial"
git clone git@github.com:bellrichm/weewx-cmon "${WEEWX_CODE_ROOT}/forks/weewx-cmon"
git clone git@github.com:bellrichm/weewx-loopdata "${WEEWX_CODE_ROOT}/forks/weewx-loopdata"
git clone git@github.com:bellrichm/weewx-nws "${WEEWX_CODE_ROOT}/forks/weewx-nws"
git clone git@github.com:bellrichm/weewx-skyfield "${WEEWX_CODE_ROOT}/forks/weewx-skyfield"
git clone git@github.com:bellrichm/weewx-wdc "${WEEWX_CODE_ROOT}/forks/weewx-wdc"
git clone git@github.com:bellrichm/weewx-xaggs "${WEEWX_CODE_ROOT}/forks/weewx-xaggs"

git -C "${WEEWX_CODE_ROOT}/forks/weewx-celestial" checkout mqtt
git -C "${WEEWX_CODE_ROOT}/forks/weewx-skyfield" checkout file_location

mkdir_p "${WEEWX_CODE_ROOT}/weewx-extensions"
git clone git@github.com:weewx-extensions/aqi-xtype "${WEEWX_CODE_ROOT}/weewx-extensions/aqi-xtype"
git clone git@github.com:weewx-extensions/development-tools "${WEEWX_CODE_ROOT}/weewx-extensions/development-tools"
git clone git@github.com:weewx-extensions/jas "${WEEWX_CODE_ROOT}/weewx-extensions/jas"
git clone git@github.com:weewx-extensions/healthchecks "${WEEWX_CODE_ROOT}/weewx-extensions/healthchecks"
git clone git@github.com:weewx-extensions/pushover "${WEEWX_CODE_ROOT}/weewx-extensions/pushover"
git clone git@github.com:weewx-extensions/test "${WEEWX_CODE_ROOT}/weewx-extensions/test"

mkdir_p "${WEEWX_CODE_ROOT}/weewx-mqtt"
git clone git@github.com:weewx-mqtt/mqttcommon "${WEEWX_CODE_ROOT}/weewx-mqtt/mqttcommon"
git clone git@github.com:weewx-mqtt/plugin-loopdata "${WEEWX_CODE_ROOT}/weewx-mqtt/plugin-loopdata"
git clone git@github.com:weewx-mqtt/publish "${WEEWX_CODE_ROOT}/weewx-mqtt/publish"
git clone git@github.com:weewx-mqtt/replicate "${WEEWX_CODE_ROOT}/weewx-mqtt/replicate"
git clone git@github.com:weewx-mqtt/subscribe "${WEEWX_CODE_ROOT}/weewx-mqtt/subscribe"

mkdir_p "${WEEWX_CODE_ROOT}/weewx-releases"
wget -P "${WEEWX_CODE_ROOT}/weewx-releases" https://weewx.com/downloads/released_versions/weewx-5.5.2.tgz 
tar -xzf "${WEEWX_CODE_ROOT}/weewx-releases/weewx-5.5.2.tgz" -C "${WEEWX_CODE_ROOT}/weewx-releases/"
rm "${WEEWX_CODE_ROOT}/weewx-releases/weewx-5.5.2.tgz"

wget -P "${WEEWX_CODE_ROOT}/weewx-releases" https://weewx.com/downloads/released_versions/weewx-5.0.0.tgz 
tar -xzf "${WEEWX_CODE_ROOT}/weewx-releases/weewx-5.0.0.tgz" -C "${WEEWX_CODE_ROOT}/weewx-releases/"
rm "${WEEWX_CODE_ROOT}/weewx-releases/weewx-5.0.0.tgz"

git clone git@github.com:weewx/weewx "${WEEWX_CODE_ROOT}/weewx-releases/weewx-clone"
git clone git@github.com:bellrichm/weewx "${WEEWX_CODE_ROOT}/weewx-releases/weewx-fork"
ln -s ../weewx-releases/weewx-fork "${WEEWX_CODE_ROOT}/weewx-mqtt"
ln -s ../weewx-releases/weewx-clone "${WEEWX_CODE_ROOT}/weewx-mqtt"

ln -s "${WEEWX_CODE_ROOT}/weewx-releases/weewx-fork" weewx

ln -s "${WEEWX_CODE_ROOT}/weewx-extensions/aqi-xtype/bin/user/aqitype.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/WeeWX-Extras/bin/user/backup.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-belchertown/bin/user/belchertown.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-mqtt/plugin-loopdata/bin/user/mqttloopdata.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-celestial/bin/user/celestial_page.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-celestial/bin/user/celestial_sky.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-celestial/bin/user/celestial.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-cmon/bin/user/cmon.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-extensions/healthchecks/bin/user/healthchecks.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/fuzzy-archer/bin/user/historygenerator.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-extensions/jas/bin/user/jas_templates.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-extensions/jas/bin/user/jas.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/fuzzy-archer/bin/user/jsonengine.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/fuzzy-archer/bin/user/largeimagegenerator.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-loopdata/bin/user/loopdata.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/vds-weewx-v3-mem-extension/bin/user/mem.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-mqtt/publish/bin/user/mqttaggregatevalues.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-mqtt/publish/bin/user/mqttarchivevalues.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-mqtt/mqttcommon/bin/user/mqttcommon.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-mqtt/publish/bin/user/mqttconfigha.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-mqtt/publish/bin/user/mqtthaconfig.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-mqtt/plugin-loopdata/bin/user/mqttloopdata.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-mqtt/publish/bin/user/mqttmessagetracker.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-mqtt/publish/bin/user/mqttpublish.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-mqtt/replicate/bin/user/mqttreplicate.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-mqtt/subscribe/bin/user/mqttsubscribe.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-mqtt/publish/bin/user/mqtttracker.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-extensions/pushover/bin/user/notify.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-nws/bin/user/nws.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/WeeWX-Extras/bin/user/observationtime.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-extensions/pushover/bin/user/pushover.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/WeeWX-Extras/bin/user/replicatedb.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/weewx-mqtt/replicate/bin/user/run_mqttreplicate.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/WeeWX-Extras/bin/user/runreports.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/fuzzy-archer/bin/user/sunevents.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-wdc/bin/user/weewx_wdc.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-skyfield/bin/user/wxskyfield_de421.bsp" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-skyfield/bin/user/wxskyfield_lines.dat" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-skyfield/bin/user/wxskyfield_sky.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-skyfield/bin/user/wxskyfield_stars.dat.gz" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-skyfield/bin/user/wxskyfield.py" "${WEEWX_DATA_DIR}/bin/user"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-xaggs/bin/user/xaggs.py" "${WEEWX_DATA_DIR}/bin/user"

ln -s "${WEEWX_CODE_ROOT}/weewx-extensions/aqi-xtype/skins/aqitype" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-belchertown/skins/Belchertown" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/forks/fuzzy-archer/skins/Bootstrap" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-celestial/skins/Celestial" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-cmon/skins/cmon" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/WeeWX-Extras/skins" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/WeeWX-Extras/skins/develop" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/weewx-extensions/healthchecks/skins/healthchecks" "${WEEWX_DATA_DIR}/skins"
ln -s ../../weewx/src/weewx_data/skins/Horizon "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/weewx-extensions/jas/skins/jas" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-loopdata/skins/LoopData" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/forks/vds-weewx-v3-mem-extension/skins/mem" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-celestial/skins/MQTTCelestial" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/weewx-mqtt/plugin-loopdata/skins/MQTTLoopData" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-nws/skins/nws" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-loopdata/skins/ScriptData" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-skyfield/skins/Skyfield" "${WEEWX_DATA_DIR}/skins"
ln -s "${WEEWX_CODE_ROOT}/forks/weewx-wdc/skins/weewx-wdc" "${WEEWX_DATA_DIR}/skins"


"${WEEWX_CODE_ROOT}/configs/extensions/development-config.sh"

"${WEEWX_CODE_ROOT}/WeeWX-Extras/utils/listVersions.py"

# pyenv install 3.15
# pyenv global 3.15
# pip install configobj
# pip install ct3
# pip install Pillow
# pip install paho.mqtt
# pip install jplephem
# pip install skyfield


${PYTHON} weewx/src/weectl.py station create "${WEEWX_DATA_DIR}" --no-prompt

mkdir_p "${WEEWX_DATA_DIR}/run"

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

${PYTHON} weewx/src/weewxd.py --config "${WEEWX_DATA_DIR}/weewx.conf"
