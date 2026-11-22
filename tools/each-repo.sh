#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Run a command in every git checkout under a directory, with that checkout
#    as the working directory, so one command can be applied across a whole
#    workspace of repositories.
#
#    Usage: each-repo.sh [--directory DIR] [--latest] <command...> [command arguments...]
#
set -uo pipefail

usage() {
    cat <<'EOF'
usage: each-repo.sh [--directory DIR] [--latest] <command...> [command arguments...]

Run <command...> in every git checkout under DIR, with the checkout as the
working directory; the arguments after the command are passed through as-is.
The command is resolved in each checkout, so use a name on PATH or an absolute
path.

DIR defaults to the current directory. Exits non-zero when a command fails or
no checkouts are found.

  --directory DIR  The directory to search for checkouts. Default: the
                   current directory.
  --latest         Only the checkouts that carry the floating latest tag, the
                   repositories that follow the versioning workflow.
  -h, --help       Show this help.

Examples:

  each-repo.sh update-repo.sh
  each-repo.sh --latest git status
  each-repo.sh --directory ~/weewx_code/weewx-extensions tagversions.sh --check
EOF
}

directory=.
latest=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        --directory)
            if [ "$#" -lt 2 ]; then
                echo "each-repo.sh: --directory needs a value." >&2
                usage >&2
                exit 2
            fi
            directory="$2"
            shift 2
            ;;
        --latest) latest=1; shift ;;
        *)
            # Whatever is left is the command and its arguments; the first
            # value ends the option loop, the rest pass through untouched.
            break
            ;;
    esac
done

cmd=("$@")

if [ "${#cmd[@]}" -eq 0 ]; then
    echo "each-repo.sh: a command is required." >&2
    usage >&2
    exit 2
fi

if [ ! -d "${directory}" ]; then
    echo "each-repo.sh: ${directory} is not a directory." >&2
    exit 1
fi

status=0
found=0

for dir in "${directory}"/*/; do
    repo="${dir%/}"
    # A worktree or submodule has .git as a file rather than a directory, so
    # existence rather than -d is what identifies a checkout here.
    if [ ! -e "${repo}/.git" ]; then
        continue
    fi

    # Only the repositories that follow the versioning workflow carry the
    # floating latest tag; a symlinked WeeWX release or a sample checkout
    # does not, and is not one of the repositories --latest addresses.
    if [ "${latest}" -eq 1 ] &&
       ! git -C "${repo}" rev-parse -q --verify refs/tags/latest >/dev/null 2>&1; then
        continue
    fi

    found=1
    echo
    echo "${repo}: ${cmd[*]}"
    if ! (cd "${repo}" && "${cmd[@]}"); then
        echo "each-repo.sh: ${repo}: ${cmd[*]} failed." >&2
        status=1
    fi
done

if [ "${found}" -eq 0 ]; then
    if [ "${latest}" -eq 1 ]; then
        echo "each-repo.sh: no git checkouts with a latest tag under ${directory}." >&2
    else
        echo "each-repo.sh: no git checkouts under ${directory}." >&2
    fi
    exit 1
fi

exit "${status}"
