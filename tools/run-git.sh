#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    Run a git command in every subdirectory that is a git checkout, so one
#    command can be applied across a whole workspace of repositories: status,
#    fetch, push, log, and so on, with the arguments after the command passed
#    through as-is.
#
#    Usage: run-git.sh [DIRECTORY] <git command...> [git command arguments...]
#
set -uo pipefail

usage() {
    cat <<'EOF'
usage: run-git.sh [DIRECTORY] <git command...> [git command arguments...]

Run <git command...> in every subdirectory of DIRECTORY that is a git
checkout, as `git -C <subdir> <git command...> [arguments...]`; the
arguments after the command are passed through as-is.

DIRECTORY defaults to the current directory, so run it from the workspace
whose repositories you want to address.

  -h, --help            Show this help.
  --directory DIR      The directory to search for checkouts. Default: the
                       current directory.

Examples:

  run-git.sh status
  run-git.sh --directory ~/weewx_code/weewx-extensions fetch --all
EOF
}

directory=.
git_command=()

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --directory)
            if [ "$#" -lt 2 ]; then
                echo "run-git.sh: --directory needs a value." >&2
                usage >&2
                exit 2
            fi
            directory="$2"
            shift 2
            ;;
        *)
            # Whatever is left is the git command and its arguments; the first
            # value ends the option loop, the rest pass through untouched.
            break
            ;;
    esac
done
git_command=("$@")

if [ "${#git_command[@]}" -eq 0 ]; then
    echo "run-git.sh: a git command is required." >&2
    usage >&2
    exit 2
fi

if [ ! -d "${directory}" ]; then
    echo "run-git.sh: ${directory} is not a directory." >&2
    exit 1
fi

status=0
for dir in "${directory}"/*/; do
    repo="${dir%/}"
    if [ ! -d "${repo}" ]; then
        # No subdirectory matched the glob; nothing to report.
        continue
    fi
    # A worktree or submodule has .git as a file rather than a directory, so
    # existence rather than -d is what identifies a checkout here.
    if [ ! -e "${repo}/.git" ]; then
        echo "skipping ${repo}: not a git repository"
        continue
    fi
    echo
    echo "git -C ${repo} ${git_command[*]}"
    if ! git -C "${repo}" "${git_command[@]}"; then
        echo "run-git.sh: ${repo}: git ${git_command[*]} failed." >&2
        status=1
    fi
done

exit "${status}"
