#! /bin/bash
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
#    Dispatch a workflow on GitHub and watch the run until it finishes.
#
#    Usage: tools/runworkflow.sh <workflow.yml>
#
#    Run it from the repository whose workflow it is (gh uses the current
#    directory), and the workflow must be on that repository's default branch.

WORKFLOW=$1

if [ -z "$WORKFLOW" ]; then
    echo "usage: $0 <workflow.yml>" >&2
    exit 1
fi

gh workflow run "$WORKFLOW" && gh run watch "$(gh run list -w "$WORKFLOW" -L 1 --json databaseId -q '.[0].databaseId')"
