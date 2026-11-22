#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Pull the git checkouts in a directory of repositories and update their
#    tags, so a local copy of a shared repository can be brought current with
#    its upstream. A single checkout can be passed instead of the directory
#    that holds it.
#
#    Usage: update-repos.sh [DIRECTORY]
#
set -uo pipefail

usage() {
    cat <<'EOF'
usage: update-repos.sh [DIRECTORY]

Pull every git checkout in DIRECTORY and update its tags. If DIRECTORY is
itself a checkout, only that one is updated. DIRECTORY defaults to the
weewx-contrib directory of the development tree.

  -h, --help  Show this help.
EOF
}

directory="${HOME}/weewx_code/weewx-contrib"
directory_set=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --directory)
            if [ "$#" -lt 2 ]; then
                echo "update-repos.sh: --directory needs a value." >&2
                usage >&2
                exit 2
            fi
            directory="$2"
            directory_set=1
            shift 2
            ;;
        -*)
            echo "update-repos.sh: unknown argument '${1}'." >&2
            usage >&2
            exit 2
            ;;
        *)
            if [ "${directory_set}" -eq 1 ]; then
                echo "update-repos.sh: unexpected argument '${1}'." >&2
                usage >&2
                exit 2
            fi
            directory="$1"
            directory_set=1
            shift
            ;;
    esac
done

if [ ! -d "${directory}" ]; then
    echo "update-repos.sh: ${directory} is not a directory." >&2
    exit 1
fi

status=0

update_repo() {
    local repo="$1"

    echo "update ${repo}"
    if git -C "${repo}" fetch --tags --prune; then
        if git -C "${repo}" pull --ff-only; then
            return 0
        fi
        echo "update-repos.sh: ${repo}: pull failed." >&2
        status=1
    else
        echo "update-repos.sh: ${repo}: fetch failed." >&2
        status=1
    fi
}

if [ -e "${directory}/.git" ]; then
    update_repo "${directory}"
else
    for dir in "${directory}"/*/; do
        repo="${dir%/}"
        if [ ! -e "${repo}/.git" ]; then
            continue
        fi
        update_repo "${repo}"
    done
fi

exit "${status}"
