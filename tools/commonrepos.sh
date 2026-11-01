#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Copy the files of the shared repositories into this repository, or with
#    --check, report the ones that differ.
#
#    Each shared repository lists the files a consumer carries in its
#    common-files.txt. Only the repositories named in WEEWX_COMMON_REPOS are
#    considered; the copies are shipped (install.py lists them), so they stay in
#    the repository and this only keeps them in step with the source of truth.
#
set -euo pipefail

# The directory holding the shared repositories' sibling checkouts.
SRC_DIR=${WEEWX_COMMON_SRC:-..}

check=0
if [ "${1:-}" == '--check' ]; then
    check=1
fi

REPOS=${WEEWX_COMMON_REPOS:-}
if [ -z "${REPOS//[[:space:]]/}" ]; then
    echo "No common repositories are declared, skipping."
    exit 0
fi

status=0
while read -r url ref; do
    if [ -z "${url}" ]; then
        continue
    fi

    # The workflow's format is '<url> <ref>'; the ref only matters there, the
    # checkout here is whatever the developer has.
    : "${ref}"

    name=${url%/}
    name=${name##*/}
    name=${name%.git}
    repo_dir="${SRC_DIR}/${name}"
    manifest="${repo_dir}/common-files.txt"

    if [ ! -d "${repo_dir}" ]; then
        # Only the check may skip: CI compares against the repository, so a
        # contributor without the checkout is not blocked. Copying cannot.
        if [ "${check}" == "1" ]; then
            echo "No ${repo_dir} checkout, skipping. Set WEEWX_COMMON_SRC to check."
            continue
        fi
        echo "${repo_dir} does not exist. Set WEEWX_COMMON_SRC to the checkouts' parent."
        exit 1
    fi

    if [ ! -f "${manifest}" ]; then
        echo "Missing ${manifest}"
        status=1
        continue
    fi

    while read -r file; do
        case "${file}" in
            ''|'#'*) continue ;;
        esac

        if [ "${check}" == "1" ]; then
            if [ ! -f "${file}" ]; then
                echo "${url} declares ${file}, but this repository does not vendor it."
                status=1
                continue
            fi

            if ! diff -u "${repo_dir}/${file}" "${file}"; then
                echo "${file} differs from ${repo_dir}/${file}"
                status=1
            fi
        else
            cp "${repo_dir}/${file}" "${file}"
            echo "Wrote ${file}"
        fi
    done < "${manifest}"
done <<< "${REPOS}"

exit "${status}"
