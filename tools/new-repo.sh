#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Create a new repository: make DIR/NAME, git-init it on the branch the
#    workspaces use, master, unless -b says otherwise, and copy the templated
#    files into it: .devenv, .env, docs/, .github/workflows/,
#    sonar-project.properties. Run it from the workspace you want the
#    repository to join — weewx-mqtt and weewx-extensions both qualify — or
#    pass it with -d. The new repository's name fills the values that are the
#    repository's own; the rest still read REPLACE_ME.
#
#    Usage: new-repo.sh [-b BRANCH] [-d DIR] NAME
#
set -uo pipefail

usage() {
    cat <<'EOF'
usage: new-repo.sh [-b BRANCH] [-d DIR] NAME

Create a new repository: make DIR/NAME, git-init it on the branch the
workspaces use, master, and copy the templated files into it — .devenv,
.env, docs/, .github/workflows/, sonar-project.properties. The new
repository's name fills the values that are the repository's own; the rest
still read REPLACE_ME.

  -b BRANCH  The initial branch name, overriding the default, master.
  -d DIR     The workspace directory to create NAME in. Default: the current
             directory, so run it from the workspace you want: weewx-mqtt or
             weewx-extensions both qualify.
EOF
}

branch=master
dir=.
name=

while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -b|--branch)
            if [ "$#" -lt 2 ]; then
                echo "new-repo.sh: $1 needs a value." >&2
                usage >&2
                exit 2
            fi
            branch="$2"
            shift 2
            ;;
        -d|--dir)
            if [ "$#" -lt 2 ]; then
                echo "new-repo.sh: $1 needs a value." >&2
                usage >&2
                exit 2
            fi
            dir="$2"
            shift 2
            ;;
        -*)
            echo "new-repo.sh: unknown argument '$1'." >&2
            usage >&2
            exit 2
            ;;
        *)
            if [ -n "$name" ]; then
                echo "new-repo.sh: unexpected argument '$1'." >&2
                usage >&2
                exit 2
            fi
            name="$1"
            shift
            ;;
    esac
done

if [ -z "$name" ]; then
    echo "new-repo.sh: NAME is required." >&2
    usage >&2
    exit 2
fi
case "$name" in
    .|..|*/*)
        echo "new-repo.sh: bad repository name '${name}'." >&2
        exit 2
        ;;
esac

if [ ! -d "${dir}" ]; then
    echo "new-repo.sh: ${dir} is not a directory." >&2
    exit 1
fi

target="${dir}/${name}"
if [ -e "${target}" ]; then
    echo "new-repo.sh: ${target} already exists." >&2
    exit 1
fi

if ! git init -q -b "${branch}" "${target}"; then
    echo "new-repo.sh: git init failed for ${target}." >&2
    exit 1
fi

echo "Created ${target} (branch: ${branch})"

# The templates live one level above tools/.
devtools_dir=$(cd "$(dirname "$0")/.." && pwd -P)

# Copy one template — a file or a tree — into the new repository. The
# destination's parent is made first, so .github/workflows/ finds its parent.
scaffold() {
    local dest="$1"
    local src="$2"

    if ! mkdir -p "$(dirname "${target}/${dest}")"; then
        echo "new-repo.sh: mkdir $(dirname "${target}/${dest}") failed." >&2
        return 1
    fi
    if ! cp -R "${devtools_dir}/${src}" "${target}/${dest}"; then
        echo "new-repo.sh: scaffolding ${dest} failed." >&2
        return 1
    fi
    echo "Scaffolded ${target}/${dest}"
    return 0
}

# Replace PATTERN with REPLACEMENT in FILE. A temp file rather than -i:
# macOS ships BSD sed, which spells -i differently.
substitute() {
    local file="$1"
    local pattern="$2"
    local replacement="$3"
    local tmp

    # A & in the replacement means the whole match to sed; escape it.
    replacement=$(printf '%s' "${replacement}" | sed 's/&/\\&/g')

    tmp=$(mktemp "${TMPDIR:-/tmp}/new-repo.XXXXXX") || return 1
    if ! sed "s|${pattern}|${replacement}|" "${file}" > "${tmp}"; then
        rm -f "${tmp}"
        echo "new-repo.sh: substituting in ${file} failed." >&2
        return 1
    fi
    mv "${tmp}" "${file}"
    return 0
}

status=0
scaffold .devenv .devenv-template || status=1
scaffold .env .env-template || status=1
scaffold docs docs-template || status=1
scaffold .github/workflows workflows-template || status=1
scaffold sonar-project.properties sonar-project.properties-template || status=1

# The new repository's name fills the values that are the repository's own;
# the owner, the workspace the new repository lives in, fills the owner ones.
workspace=$(basename "$(cd "${dir}" && pwd -P)")
substitute "${target}/.devenv" 'WEEWX_MODULE_NAME=REPLACE_ME' "WEEWX_MODULE_NAME=${name}" || status=1
substitute "${target}/.devenv" './bin/user/REPLACE_ME.py' "./bin/user/${name}.py" || status=1
substitute "${target}/docs/_config.yml" 'title: REPLACE_ME' "title: ${name}" || status=1
substitute "${target}/docs/_config.yml" 'baseurl: "/REPLACE_ME"' "baseurl: \"/${name}\"" || status=1
substitute "${target}/docs/_config.yml" 'url: "https://REPLACE_ME"' "url: \"https://${workspace}.github.io\"" || status=1
substitute "${target}/docs/readme.md" 'https://REPLACE_ME.github.io/REPLACE_ME/home/' "https://${workspace}.github.io/${name}/home/" || status=1
substitute "${target}/docs/readme.md" 'https://github.com/REPLACE_ME/REPLACE_ME/issues/new' "https://github.com/${workspace}/${name}/issues/new" || status=1
substitute "${target}/docs/readme.md" 'https://github.com/REPLACE_ME/REPLACE_ME/discussions/new' "https://github.com/${workspace}/${name}/discussions/new" || status=1
substitute "${target}/sonar-project.properties" 'sonar.projectKey=REPLACE_ME_REPLACE_ME' "sonar.projectKey=${workspace}_${name}" || status=1
substitute "${target}/sonar-project.properties" 'sonar.organization=REPLACE_ME' "sonar.organization=${workspace}" || status=1
for file in "${target}"/.github/workflows/*.yml; do
    [ -f "${file}" ] || continue
    substitute "${file}" "module-name: 'REPLACE_ME'" "module-name: '${name}'" || status=1
done

if [ "${status}" -eq 0 ]; then
    echo "Fill in the REPLACE_ME values as they become known."
    echo
    echo "To push to GitHub:"
    echo "    git remote add origin git@github.com:${workspace}/${name}.git"
    echo "    git add -A"
    echo "    git commit -m 'Initial commit'"
    echo "    git push -u origin ${branch}"
fi

exit "${status}"
