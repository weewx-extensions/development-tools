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
#    Usage: tagversions.sh [-C DIR] [--check] [--push] [--no-latest]
#
set -euo pipefail

check=0
push=0
latest=1
repo=.

usage() {
    cat <<'EOF'
usage: tagversions.sh [-C DIR] [--check] [--push] [--no-latest]

Create or repair the floating vX, vX.Y, and latest tags from the final
release tags (vX.Y.Z).

  -C, --repo DIR  The checkout to tag. Default: the current directory.
  --check         Report missing or stale tags, change nothing.
  --push          Push the tags this updates to origin.
  --no-latest     Leave the latest tag alone.
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        -C|--repo)
            if [ "$#" -lt 2 ]; then
                echo "tagversions.sh: $1 needs a value." >&2
                usage >&2
                exit 2
            fi
            repo="$2"
            shift 2
            ;;
        --check) check=1; shift ;;
        --push) push=1; shift ;;
        --no-latest) latest=0; shift ;;
        -h|--help) usage; exit 0 ;;
        *)
            echo "tagversions.sh: unknown argument '$1'." >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [ "${check}" == "1" ] && [ "${push}" == "1" ]; then
    echo "tagversions.sh: --check and --push cannot be combined." >&2
    exit 2
fi

if [ ! -d "${repo}" ]; then
    echo "tagversions.sh: ${repo} is not a directory." >&2
    exit 1
fi

if ! git -C "${repo}" rev-parse --git-dir >/dev/null 2>&1; then
    echo "tagversions.sh: ${repo} is not a git checkout." >&2
    exit 1
fi

# What to apply, '<name> <tag>' per line: the minor keys, then the major keys,
# then latest. git orders the releases by version, so the last tag seen for a
# key is the newest and the keys come out in ascending order. The mapping is
# built with awk because the bash 3.2 macOS ships has no associative arrays and
# its sort has no version ordering.
plan=$(git -C "${repo}" tag --list 'v*' --sort=v:refname | awk -F. '
    $0 !~ /^v[0-9]+\.[0-9]+\.[0-9]+$/ { next }
    {
        major = $1
        minor = $1 "." $2
        if (!(minor in minor_tag)) { minor_order[++minors] = minor }
        if (!(major in major_tag)) { major_order[++majors] = major }
        minor_tag[minor] = $0
        major_tag[major] = $0
        newest = $0
    }
    END {
        for (i = 1; i <= minors; i++) { print minor_order[i], minor_tag[minor_order[i]] }
        for (i = 1; i <= majors; i++) { print major_order[i], major_tag[major_order[i]] }
        if (newest != "") { print "latest", newest }
    }')

if [ -z "${plan}" ]; then
    echo "tagversions.sh: no final release tags (vX.Y.Z) found." >&2
    exit 1
fi

status=0
updated=0

short() {
    git -C "${repo}" rev-parse --short "$1"
}

apply() {
    local name=$1
    local tag=$2
    local target
    local current=''
    target=$(git -C "${repo}" rev-parse "${tag}^{commit}")

    if git -C "${repo}" rev-parse -q --verify "refs/tags/${name}^{commit}" >/dev/null 2>&1; then
        current=$(git -C "${repo}" rev-parse "refs/tags/${name}^{commit}")
    fi

    if [ "${current}" == "${target}" ]; then
        return 0
    fi

    if [ "${check}" == "1" ]; then
        if [ -z "${current}" ]; then
            echo "${name} is missing, expected $(short "${target}")"
        else
            echo "${name} points to $(short "${current}"), expected $(short "${target}")"
        fi
        status=1
        return 0
    fi

    git -C "${repo}" tag -f "${name}" "${target}" >/dev/null

    if [ "${push}" == "1" ]; then
        git -C "${repo}" push --force origin "refs/tags/${name}"
    else
        echo "Set ${name} to ${tag}"
    fi
    updated=$((updated + 1))
}

while read -r name tag; do
    if [ "${name}" == "latest" ] && [ "${latest}" != "1" ]; then
        continue
    fi
    apply "${name}" "${tag}"
done <<< "${plan}"

if [ "${status}" == "0" ] && [ "${updated}" == "0" ]; then
    echo "All floating tags are up to date."
fi

exit "${status}"
