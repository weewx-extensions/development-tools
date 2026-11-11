#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Create or repair the floating major (vX), minor (vX.Y), and latest tags
#    from the final release tags (vX.Y.Z), or with --check, report the ones
#    that are missing or stale.
#
#    Only final releases are considered; prereleases such as v1.2.3-rc.1 are
#    ignored. The tags are written locally; --push updates origin as well.
#    Fetch first so the local tags include the releases you want to cover.
#
#    Usage: tagversions.sh [--check] [--push] [--no-latest]
#
set -euo pipefail

check=0
push=0
latest=1

usage() {
    cat <<'EOF'
usage: tagversions.sh [--check] [--push] [--no-latest]

Create or repair the floating vX, vX.Y, and latest tags from the final
release tags (vX.Y.Z).

  --check      Report missing or stale tags, change nothing.
  --push       Push the tags this updates to origin.
  --no-latest  Leave the latest tag alone.
EOF
}

for arg in "$@"; do
    case "${arg}" in
        --check) check=1 ;;
        --push) push=1 ;;
        --no-latest) latest=0 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown argument: ${arg}" >&2; usage >&2; exit 2 ;;
    esac
done

if [ "${check}" == "1" ] && [ "${push}" == "1" ]; then
    echo "--check and --push cannot be combined." >&2
    exit 2
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Run this from a git checkout." >&2
    exit 1
fi

declare -A major_tags=()
declare -A minor_tags=()
newest=''

# Ascending order leaves the newest release in each key.
while read -r tag; do
    if [[ ! "${tag}" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        continue
    fi

    major_tags["v${BASH_REMATCH[1]}"]=${tag}
    minor_tags["v${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"]=${tag}
    newest=${tag}
done < <(git tag --list 'v*' --sort=v:refname)

if [ -z "${newest}" ]; then
    echo "No final release tags (vX.Y.Z) found." >&2
    exit 1
fi

status=0
updated=0

apply() {
    local name=$1
    local tag=$2
    local target
    local current=''
    target=$(git rev-parse "${tag}^{commit}")

    if git rev-parse -q --verify "refs/tags/${name}^{commit}" >/dev/null 2>&1; then
        current=$(git rev-parse "refs/tags/${name}^{commit}")
    fi

    if [ "${current}" == "${target}" ]; then
        return 0
    fi

    if [ "${check}" == "1" ]; then
        if [ -z "${current}" ]; then
            echo "${name} is missing, expected $(git rev-parse --short "${target}")"
        else
            echo "${name} points to $(git rev-parse --short "${current}"), expected $(git rev-parse --short "${target}")"
        fi
        status=1
        return 0
    fi

    git tag -f "${name}" "${target}" >/dev/null

    if [ "${push}" == "1" ]; then
        git push --force origin "refs/tags/${name}"
    else
        echo "Set ${name} to ${tag}"
    fi
    updated=$((updated + 1))
}

while read -r name; do
    apply "${name}" "${minor_tags[${name}]}"
done < <(printf '%s\n' "${!minor_tags[@]}" | sort -V)

while read -r name; do
    apply "${name}" "${major_tags[${name}]}"
done < <(printf '%s\n' "${!major_tags[@]}" | sort -V)

if [ "${latest}" == "1" ]; then
    apply latest "${newest}"
fi

if [ "${status}" == "0" ] && [ "${updated}" == "0" ]; then
    echo "All floating tags are up to date."
fi

exit "${status}"
