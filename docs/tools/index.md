---
title: Development Tools
has_children: true
has_toc: true
nav_order: 3
---

The scripts in `tools/` run the same checks as the `analyze-test` GitHub Actions workflow,
so a local run and a CI run agree on what passes.

Run them from the root of an extension repository, after sourcing its `.devenv`:

```bash
source .devenv
verify.sh
```

A repository's `.devenv` bootstraps `$WEEWX_TOOL_PATH` and sources the shared
`tools/devenv.sh`, which puts that directory on `PATH`, selects the development
default Python from `supported-pythons`, and sets the other shared settings.

The environment check and the test suites can be run on more than one interpreter, one `--python`
per pyenv version, so the oldest and the newest the project supports are covered in a single pass:

```bash
verify.sh --python 3.9.13 --python 3.15.2
```

Only the steps whose result depends on the interpreter are repeated. `lint.sh` and the other
static checks run once, on the newest supported version, as the workflow lints a single matrix
cell. The versions must already be installed in pyenv; a prefix such as `3.9` resolves to the
installed version.

The supported versions live in `tools/supported-pythons`, one per line, oldest first: the first is
the development default and the last is the latest. `tools/versions.sh` reads them, and the tools
read them from there; `verify.sh` runs its `--check`, which reports a workflow, the
`.devenv-template`, or a consumer's `.devenv` that disagrees with it, and a `.devenv` that pins a
version rather than sourcing the shared `devenv.sh`. The development default is the oldest, so a
newer language feature fails locally rather than in the oldest CI cell.

## Provisioning a development machine

`setup.sh` provisions a development machine from the repositories in its `EDIT THESE` block: it
links the extension modules and the skins into the station, links the release checkouts, and
reports every action. It is idempotent — a second run reports `0 created, 100 skipped` — and it
never deletes.

It leaves to the operator the rest of the provisioning:

- Assembling the station's `weewx.conf` from the fragments in the `configs` repository:
  `configs/extensions/development-config.sh`.
- Listing the WeeWX versions the tools should be checked against: `weewx-extensions/development-tools/tools/listVersions.py`.
- Installing the per-interpreter dependencies: `pyenv install` for the versions in
  `tools/supported-pythons` (the first is the development default), then per version
  `pip install configobj`, `pip install ct3`, `pip install Pillow`, `pip install paho.mqtt`,
  `pip install jplephem`, `pip install skyfield`, and `pip install boto3 six` for the AWS-S3
  report's upload generator.

```bash
setup.sh            # run from $HOME; the manual steps above are the rest of the provisioning
```

A copy of the script can also be fetched straight from the repository with wget instead of
cloning it:

```bash
wget -O setup.sh https://raw.githubusercontent.com/weewx-extensions/development-tools/master/tools/setup.sh
```

## Platforms

The scripts run on Linux, which is what CI uses, and on macOS. They are written for bash 3.2, the
`/bin/bash` macOS ships, and for the utilities both systems provide, so they need neither Homebrew's
bash nor coreutils.

The mosquitto broker is the one macOS difference: Homebrew installs it into `/opt/homebrew/sbin`,
which it keeps off `PATH`, and the integration tests skip themselves without the binary. Add it:

```bash
export PATH="/opt/homebrew/sbin:$PATH"
```

`checkenv.sh` reports that binary as missing, so a skipped suite does not pass unnoticed.

The e2e suite uses the default port, so it needs a broker at `localhost:1883`;
`brew services start mosquitto` on macOS. `checkenv.sh` reports that one too, when the e2e suite is
configured.

`tagversions.sh` takes its version order from `git` and maps the releases with `awk`, and
`watch*.sh` poll with `find`, so neither needs GNU `sort` or `inotifywait`.

## Scripts

| Script | Does | Corresponding CI step |
| --- | --- | --- |
| `actionlint.sh` | Lints `.github/workflows`, downloading the pinned actionlint into `tools/` on first use. | Lint the workflows |
| `alltests.sh` | Runs the suites in `WEEWX_TEST_SUITES`, skipping suites with no directory, and stops at the first failure. | All of the test steps |
| `build-pythons.sh` | Rebuilds pyenv interpreters against Homebrew's SQLite (and the OpenSSL each one uses); `--verify-only` checks them. macOS only. | - |
| `checkenv.sh` | Verifies weewx, paho, the tools, and the brokers the integration and e2e suites need. Reports every miss at once, and notes an interpreter outside the supported versions. | Install dependencies |
| `commonrepos.sh` | Copies the files of the shared repositories; `--check` reports drift. | Check the common repositories |
| `configs.sh` | Copies the shared config files from `development-tools/config`; with `--check`, fails when a copy has drifted. | - |
| `cov-func.sh` | Measures function test coverage, writes the HTML and XML reports. | - |
| `coverage.sh` | Measures unit test coverage, writes the HTML and XML reports. | Code Coverage |
| `devenv.sh` | The shared settings every repository sources from its `.devenv`; selects the development default Python and the `WEEWX_*` defaults. | - |
| `e2etests.sh` | Runs `bin/user/tests/e2e`. | E2E tests |
| `each-repo.sh` | Runs a command in every git checkout under a directory, with the checkout as the working directory; `--directory DIR` selects the directory. | - |
| `functests.sh` | Runs `bin/user/tests/func`. | Function tests |
| `integtests.sh` | Runs `bin/user/tests/integ` with `--import-mode=append`. | Integration tests |
| `lint.sh` | Runs pylint and flake8 over `WEEWX_LINT_PATHS` on the newest supported version, failing if either reports unless `WEEWX_LINT_FAIL` is `0`. | Lint with pylint / flake8 |
| `new-repo.sh` | Creates a new repository: `git init` of `DIR/NAME` on the workspaces' branch, `master` (override with `-b`), and copies the templated files into it — `.devenv`, `.env`, `changes.txt`, `docs/`, `.github/workflows/`, `sonar-project.properties` — where values are not yet known they read `REPLACE_ME` and the new repository's name fills the values that are its own. Run it from the workspace you want — `weewx-mqtt` or `weewx-extensions` both qualify. | - |
| `refs.sh` | Points the reusable workflow refs at the current major version tag, or with `--check`, reports the stale ones; `-C DIR` selects another checkout. | - |
| `run-git.sh` | Runs a git command in every subdirectory of a directory that is a git checkout, passing the command and its arguments through as-is; `--directory DIR` selects the directory. | - |
| `runworkflow.sh` | Dispatches a workflow on GitHub and watches it. | - |
| `setup.sh` | Builds the development tree under `$HOME`: clones the repositories in its `EDIT THESE` block, unpacks the WeeWX releases, and links the extension modules and skins into the station. Reports each create, skip, or error. | - |
| `sqlite-fork-repro.py` | Reproduces the fork-after-SQLite SIGSEGV, to check whether an interpreter is affected. macOS only. | - |
| `tagversions.sh` | Creates or repairs the floating `vX`, `vX.Y`, and `latest` tags from the release tags; `--check` reports drift, and `-C DIR` selects another checkout. | - |
| `unittests.sh` | Runs `bin/user/tests/unit`. | Unit tests |
| `update-repo.sh` | Pulls one checkout and updates its tags; `-C DIR` selects another checkout. | - |
| `verify.sh` | Runs `checkenv.sh`, `lint.sh`, `actionlint.sh`, `refs.sh`, `versions.sh`, `configs.sh`, `commonrepos.sh`, and `alltests.sh`; with `--python`, repeats the environment check and the tests on each version. | - |
| `versions.sh` | Reads the supported Python versions from `supported-pythons`; `--check` reports a workflow, the `.devenv-template`, or a consumer's `.devenv` that disagrees with it, and a `.devenv` that pins a version. | - |
| `watch*.sh` | Re-runs a suite, and the coverage report, when its script, the module, or the tests change. | - |

`configs.sh --check` skips a config the repository does not carry, as the workflow's check does, so
`verify.sh` passes in a repository that keeps only some of them. `development-tools` itself is one:
it keeps `.flake8` at its root and the rest under `config/`.

`actionlint.sh` treats `tools/actionlint` as a cache, not a vendored file: it is in `.gitignore`,
the cached binary is used only when it matches the pinned release, an actionlint on `PATH` stands in
when nothing is cached, and otherwise the release is downloaded. Offline, the step reports and
passes rather than blocking `verify.sh`.

`each-repo.sh` is the workspace runner: it runs any command in every checkout under a directory,
with that checkout as the working directory. `each-repo.sh update-repo.sh` is the batch form of
`update-repo.sh`, and `each-repo.sh tagversions.sh --check` or `each-repo.sh refs.sh --check` sweeps
a workspace without a `for` loop.

## Homebrew interpreters

`build-pythons.sh` and `sqlite-fork-repro.py` are the pair for one macOS problem: on
macOS 27.2.1 (Apple's libsqlite3 3.54.0) opening *any* SQLite database in a forked child died
with a SIGSEGV inside `libsqlite3.dylib`, taking the forked worker with it. Against Homebrew's
sqlite 3.54.1 the same fork survives. Every interpreter tested was affected (3.9.13, 3.10.22,
3.14.10, 3.15.2, and the system 3.9.6) and whether a process crashed at all was decided per
process, so it presented as an intermittent hang rather than a crash.

```bash
build-pythons.sh                 # rebuild and verify the oldest and newest supported versions
build-pythons.sh 3.14.10         # a version it does not know, with pyenv's OpenSSL choice
build-pythons.sh --verify-only   # report what is installed, change nothing
```

It rebuilds the interpreter, so the OpenSSL each version is built against is listed in the script,
and a bare run covers the ends of `tools/supported-pythons`. `build-pythons.sh --verify-only`
checks the extension's recorded library, the version loaded at runtime, and the OpenSSL, because
only the last two prove that the swap took effect. A plain `pyenv install -f` undoes the fix:
CPython's configure reaches `sqlite3` through Homebrew's shim for the macOS SDK, so the script
fails in preflight rather than building that.

```bash
python3 sqlite-fork-repro.py --trials 3                          # in-memory databases
python3 sqlite-fork-repro.py --database ~/weewx-data/archive.sdb # a real one
```

It forks children that each open a database, exits `0` when all survived, `1` when any was
killed, and `2` on a hang, so it can be run in a loop to compare interpreters or to confirm a
rebuild. Both scripts are macOS only, and they live here so the diagnosis stays with the fix.

## Settings

The scripts read these from the environment, normally set in `.devenv`.
`tools/common.sh` supplies the defaults and is sourced by every script.

| Setting | Default | Purpose |
| --- | --- | --- |
| `WEEWX_MODULE_NAME` | - | The module under test, e.g. `mqttsubscribe`. |
| `WEEWX_TOOL_PATH` | - | This `tools` directory, added to `PATH`. |
| `WEEWX_PYENV_VERSION` | `supported-pythons`, first entry | The development default, selected by the shared `devenv.sh`; exported as `PYENV_VERSION`. |
| `WEEWX_PYTHONPATH` | `bin` | `PYTHONPATH` for the tests. With weewx installed, `bin` is enough. |
| `WEEWX_LINT_PATHS` | `bin/user/${WEEWX_MODULE_NAME}.py` | What `lint.sh` checks, the workflow's `lint-paths` input. |
| `WEEWX_LINT_FAIL` | `1` | With `0`, `lint.sh` reports the findings without failing, the workflow's `lint-fail` input. |
| `WEEWX_COMMON_REPOS` | - | The shared repositories this repository vendors, the workflow's `common-repos` input. |
| `WEEWX_COMMON_SRC` | `..` | Where the shared repositories' sibling checkouts are. |
| `WEEWX_TEST_SUITES` | `unit func integ e2e` | What `alltests.sh` runs. |
| `WEEWX_HTML` | `0` | With `1`, writes the HTML test reports. Needs `pytest-html`. |
| `WEEWX_RESULTS_DIR` | `results` | Where the reports are written. |

The shared `tools/devenv.sh` sets the interpreter and `WEEWX_PYTHONPATH` from there; a repository
overrides either in its own `.devenv` when it needs to. `WEEWX_PYENV_VERSION` is exported as
`PYENV_VERSION`, so the `python` and `pytest` of the development shell follow it.

The workflow installs weewx from PyPI, so `WEEWX_PYTHONPATH` only needs the checkout. Until weewx is
installed, the shared `devenv.sh` points it at a checkout as well:

```bash
if PYTHONPATH= python3 -c 'import weewx' >/dev/null 2>&1; then
    export WEEWX_PYTHONPATH=bin
else
    export WEEWX_PYTHONPATH=bin:../weewx/src
fi
```

`plugin-loopdata` also adds the station's user package (`~/weewx-data/bin`), which provides
the extensions it depends on.

## Shared config files

`.pylintrc`, `.pylintrc-tests`, `.flake8`, `.coveragerc`, `.codacy.yaml`, and `requirements.txt`
are the same in every extension repository. The canonical copies live in `development-tools/config`:

```bash
configs.sh           # copy them into this repository
configs.sh --check   # report the ones that differ
```

`verify.sh` runs the check, and the analyze-test workflow compares the repository's copies with
`config-ref` (default `v6`) so a stale copy cannot reach CI.

The tests are linted as well, with `.pylintrc-tests`, which turns off the conventions that tests
legitimately break (docstrings, naming, mocks, complexity). `.codacy.yaml` keeps Codacy from
re-linting the tests with its own defaults. `lint.sh` covers
`bin/user/tests` by default; set `WEEWX_TEST_LINT_PATHS=''` to skip it.

## Shared common repositories

A module shared by several extensions, such as `mqttcommon.py` for the `weewx-mqtt` ones, lives in
its own repository and is copied in rather than edited. The extensions still ship the copy (their
`install.py` lists it), so the file stays in each repository and is pulled from the source of truth:

```bash
commonrepos.sh           # copy the shared files in
commonrepos.sh --check   # report the ones that differ
```

`commonrepos.sh` reads `WEEWX_COMMON_REPOS` (the same `<url> <ref>` lines as the workflow's `common-repos`
input) and looks for sibling checkouts under `WEEWX_COMMON_SRC` (default `..`); set that to point
elsewhere, for example to test an uncommitted change against a consumer. Each repository lists its
files in its own `common-files.txt`. `verify.sh` runs the check, and the analyze-test workflow
compares the copies at the declared ref; a repository that declares nothing is skipped.

## Floating version tags

The versioning workflow keeps `vX`, `vX.Y`, and `latest` in step with each release. To backfill a
repository or repair drift, create the tags from the releases already in the checkout:

```bash
git fetch --tags
tagversions.sh --check   # report missing or stale tags
tagversions.sh --push    # write the tags locally and force-update origin
```

Only final `vX.Y.Z` releases are considered; prereleases are ignored. `--no-latest` leaves `latest`
alone. Pass `-C DIR` to work on a checkout other than the current directory. The script is only
needed for the initial backfill or to repair drift; the workflow maintains the tags after each
release.

The floating `latest` tag is the one to diff the local checkout against, to see what a repository's
changes since its last release are:

```bash
git diff latest..HEAD             # working-tree diff against the last release
git diff --stat latest..HEAD      # summary of what changed since
git diff --name-only latest..HEAD
git log --oneline latest..HEAD     # commits since the last release

```

## Outputs

Reports go to `WEEWX_RESULTS_DIR`, the way CI archives them:

- `results/pylint.txt`, `results/pylint-tests.txt`
- `results/flake8.txt`, `results/flake8-tests.txt`
- `results/unittests.html`, `results/functests.html`, `results/integtests.html`, `results/e2etests.html` (with `WEEWX_HTML=1`)
- `results/coverage/index.html`
- `coverage.xml` in the repository root, for the coverage providers

Add `results/` and `coverage.xml` to the repository's `.gitignore`.

## What is not local

The matrix workflow also runs other Python versions, other weewx versions, and a
`paho-mqtt==1.6.1` job. Those need the workflow itself; use
[ACT](../actions/running-locally/) or `runworkflow.sh` for them.
