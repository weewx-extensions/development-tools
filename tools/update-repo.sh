#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Pull one git checkout and update its tags, so a local copy of a shared
#    repository can be brought current with its upstream. Use each-repo.sh to
#    apply it across a workspace.
#
#    Usage: update-repo.sh [-C DIR]
#
set -uo pipefail

usage() {
    cat <<'EOF'
usage: update-repo.sh [-C DIR]

Pull the checkout at DIR and update its tags. DIR defaults to the current
directory.

  -C, --repo DIR  The checkout to update. Default: the current directory.
  -h, --help      Show this help.
EOF
}

repo=.

while [ "$#" -gt 0 ]; do
    case "$1" in
        -C|--repo)
            if [ "$#" -lt 2 ]; then
                echo "update-repo.sh: $1 needs a value." >&2
                usage >&2
                exit 2
            fi
            repo="$2"
            shift 2
            ;;
        -h|--help) usage; exit 0 ;;
        *)
            echo "update-repo.sh: unknown argument '$1'." >&2
            usage >&2
            exit 2
            ;;
    esac
done

if [ ! -d "${repo}" ]; then
    echo "update-repo.sh: ${repo} is not a directory." >&2
    exit 1
fi

# Resolve once, so the report names the checkout even when DIR is '.'.
repo=$(cd "${repo}" && pwd -P)

if ! git -C "${repo}" rev-parse --git-dir >/dev/null 2>&1; then
    echo "update-repo.sh: ${repo} is not a git checkout." >&2
    exit 1
fi

echo "update ${repo}"

if ! git -C "${repo}" fetch --tags --prune; then
    echo "update-repo.sh: ${repo}: fetch failed." >&2
    exit 1
fi

if ! git -C "${repo}" pull --ff-only; then
    echo "update-repo.sh: ${repo}: pull failed." >&2
    exit 1
fi
