# AGENTS.md

`development-tools` is the shared CI and local-check toolkit for the `weewx-extensions` and
`weewx-mqtt` extension repositories: the reusable workflows those repositories call, the
`tools/` scripts that mirror them, the canonical lint/test configs, the docs and workflow
templates, and a sample extension the tooling is exercised against.

## Role & boundaries

- Consumers reference this repository's workflows **by ref** (`@v6`, `@master`, `@latest`), so
  editing `.github/workflows/` changes every consumer's CI. That needs a release and a refs bump
  (see *Release and refs*), not an in-place edit.
- The unit of work is usually "one setting, everywhere": a workflow `inputs:` entry, the
  `WEEWX_*` variable that mirrors it, the script that reads it, `.devenv-template`, and the docs
  row.
- Nothing here is a WeeWX extension. `install.py`, `bin/user/simpleclass.py` and
  `bin/user/tests/` exist so the tooling runs against a real repository layout, and the four
  suites (unit/func/integ/e2e) are the shape `alltests.sh` and the workflow assume. Keep them
  passing; they are not shipped code.

## Layout

| path | what it is |
| --- | --- |
| `.github/workflows/` | The reusable workflows (`analyze-test`, `analyze-test-matrix`, `perform-analyze-test`, `fetch`, `stale`, `versioning`) plus thin `run-*` callers that test this repository's own published refs. |
| `tools/` | The local scripts; `verify.sh` runs all of them and `common.sh` holds the shared defaults. |
| `config/` | The **published** configs (`.pylintrc`, `.pylintrc-tests`, `.flake8`, `.coveragerc`, `.codacy.yaml`, `requirements.txt`), copied into consumers by `configs.sh`. |
| `workflows-template/` | The caller workflows a consumer copies into its `.github/workflows/`. |
| `docs/`, `docs-template/` | The published Jekyll site, and what a new extension copies. |
| `.devenv-template`, `.env-template` | The settings and environment a consumer supplies. |
| `sonar-project.properties-template` | The server key for the `sonar-scan` input. |
| `bin/user/`, `install.py` | The sample extension, used as test data. |

## Canonical copies

- Never fix a lint or coverage config inside a consumer repository. Change `config/`, then run
  `configs.sh` there: `verify.sh` runs `configs.sh --check` and the workflow compares the same
  files. The same goes for `workflows-template/`, `.devenv-template` and `docs-template/`.
- This repository carries only a root `.flake8` of its own; the rest live under `config/`. See
  the note under the script table in `docs/tools/index.md` before concluding a config is
  missing.
- `tools/actionlint` is a downloaded cache, not a vendored file: it is gitignored, and
  `actionlint.sh` reuses it only when it matches the pinned release. Never commit it.

## Tools ↔ workflow inputs

- `tools/common.sh` defaults mirror the inputs of `.github/workflows/analyze-test.yml`
  (`WEEWX_LINT_PATHS` ↔ `lint-paths`, `WEEWX_TEST_SUITES` ↔ the per-suite booleans,
  `WEEWX_LINT_FAIL` ↔ `lint-fail`). A new option belongs in the workflow `inputs:`, this file,
  `.devenv-template`, the script that reads it, and `docs/tools/index.md`; leaving one out is
  how the two sides drift.
- A new script: `#! /bin/bash`, the copyright block, `set -uo pipefail` (add `-e` only where a
  failure must stop a loop, as the copy scripts do), bash 3.2 — the `/bin/bash` macOS ships, so
  no `local -a` and no `[[ ]]` where `case` will do — Linux **and** macOS, `-h/--help`, a
  `<script>:` error prefix, exit 2 on a usage error, and a row in `docs/tools/index.md`.
  Anything macOS-only says so in the header, the row, and its section; `build-pythons.sh` and
  `sqlite-fork-repro.py` are the examples.
- `verify.sh` runs the steps of one `perform-analyze-test` job and reports every one rather than
  stopping at the first: `checkenv`, `lint`, `actionlint`, `refs --check`, `configs --check`,
  `commonrepos --check`, `alltests`. `--python` repeats only the interpreter-dependent steps.

## Checking this repository

There is no `.devenv` here and no WeeWX checkout beside it, so a bare `tools/verify.sh` fails
`checkenv` on `weewx` and `lint`/`alltests` on `WEEWX_MODULE_NAME`. Run it as the sample
extension instead:

```bash
PYTHONPATH=bin WEEWX_MODULE_NAME=simpleclass \
    WEEWX_PYTHONPATH=/path/to/weewx/src ./tools/verify.sh
```

A checkout normally sits at `weewx-extensions/weewx` (see `docs/home/directory-structure.md`).
Without one, run the steps that need neither: `tools/actionlint.sh` and `/bin/bash -n` on every
changed script, plus the suite the change affects.

## Release and refs

- `.github/workflows/versioning.yml` tags a release when one is published; `tagversions.sh` then
  writes the floating `vX`, `vX.Y` and `latest` tags from the `vX.Y.Z` ones (`--check` reports
  drift, `--push` updates origin).
- `config-ref`'s `default:` in `.github/workflows/analyze-test.yml` (currently `v6`) is the knob
  consumers follow, so a new major means bumping it **and** running `tagversions.sh`.
- Order for a change that reaches consumers: `config/` or the workflow → `tools/` → docs →
  release tag → `config-ref` bump → `refs.sh` in each consumer. `refs.sh --check` finds the
  stale refs; it self-skips when run in this repository.

## Docs

- `docs/readme.md` is the project readme, rendered through `docs/index.md`. There is no root
  `README.md`, so do not add one.
- `docs/tools/index.md` is the option reference for the scripts: every tool gets a table row,
  and its own section only when a line will not do. Keep flags out of this file.
- Templates under `docs-template/` and `workflows-template/` reach every new repository; treat
  an edit there as a change to all of them.

## Commits

Never commit, push, tag or release unless explicitly asked. Propose the commit message and wait
for the go-ahead; "make this change" is not permission to commit it. Don't pre-stage.

## Cross-repo workflow

A shared change starts **here**: this is the upstream end, and it has no workspace of its own.
The consumer repositories keep their order of operations in `weewx-mqtt/workspace/AGENTS.md`,
next to the organizations' sibling checkouts.
