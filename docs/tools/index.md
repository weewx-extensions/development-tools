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

`.devenv` puts `$WEEWX_TOOL_PATH` on `PATH`, so the scripts can be run by name.

## Scripts

| Script | Does | Corresponding CI step |
| --- | --- | --- |
| `verify.sh` | Runs `checkenv.sh`, `lint.sh`, `configs.sh --check`, and `alltests.sh`, reporting every step's result. | - |
| `configs.sh` | Copies the shared config files from `development-tools/config`; with `--check`, fails when a copy has drifted. | - |
| `checkenv.sh` | Verifies weewx, paho, the tools, and the integration broker. Reports every miss at once. | Install dependencies |
| `lint.sh` | Runs pylint and flake8 over `WEEWX_LINT_PATHS`, failing if either reports. | Lint with pylint / flake8 |
| `unittests.sh` | Runs `bin/user/tests/unit`. | Unit tests |
| `functests.sh` | Runs `bin/user/tests/func`. | Function tests |
| `integtests.sh` | Runs `bin/user/tests/integ` with `--import-mode=append`. | Integration tests |
| `e2etests.sh` | Runs `bin/user/tests/e2e`. | E2E tests |
| `alltests.sh` | Runs the suites in `WEEWX_TEST_SUITES`, skipping suites with no directory, and stops at the first failure. | All of the test steps |
| `coverage.sh` | Measures unit test coverage, writes the HTML and XML reports. | Code Coverage |
| `cov-func.sh` | The same for the function tests. | - |
| `watch*.sh` | Re-runs a suite when its tests or module change, using `inotifywait`. | - |
| `runworkflow.sh` | Dispatches a workflow on GitHub and watches it. | - |

## Settings

The scripts read these from the environment, normally set in `.devenv`.
`tools/common.sh` supplies the defaults and is sourced by every script.

| Setting | Default | Purpose |
| --- | --- | --- |
| `WEEWX_MODULE_NAME` | - | The module under test, e.g. `mqttsubscribe`. |
| `WEEWX_TOOL_PATH` | - | This `tools` directory, added to `PATH`. |
| `WEEWX_PYTHONPATH` | `bin` | `PYTHONPATH` for the tests. With weewx installed, `bin` is enough. |
| `WEEWX_PYENV_VERSION` | - | Exported as `PYENV_VERSION` when set. |
| `WEEWX_LINT_PATHS` | `bin/user/${WEEWX_MODULE_NAME}.py` | What `lint.sh` checks, the workflow's `lint-paths` input. |
| `WEEWX_TEST_SUITES` | `unit func integ e2e` | What `alltests.sh` runs. |
| `WEEWX_HTML` | `0` | With `1`, writes the HTML test reports. Needs `pytest-html`. |
| `WEEWX_RESULTS_DIR` | `results` | Where the reports are written. |

The workflow installs weewx from PyPI, so `WEEWX_PYTHONPATH` only needs the checkout.
Until weewx is installed, point it at a checkout as well:

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

`.pylintrc`, `.flake8`, `.coveragerc`, and `requirements.txt` are the same in every extension
repository. The canonical copies live in `development-tools/config`:

```bash
configs.sh           # copy them into this repository
configs.sh --check   # report the ones that differ
```

`verify.sh` runs the check, and the analyze-test workflow compares the repository's copies with
`config-ref` (default `v6`) so a stale copy cannot reach CI.

## Outputs

Reports go to `WEEWX_RESULTS_DIR`, the way CI archives them:

- `results/pylint.txt`, `results/flake8.txt`
- `results/unittests.html`, `results/functests.html`, `results/integtests.html`, `results/e2etests.html` (with `WEEWX_HTML=1`)
- `results/coverage/index.html`
- `coverage.xml` in the repository root, for the coverage providers

Add `results/` and `coverage.xml` to the repository's `.gitignore`.

## What is not local

The matrix workflow also runs other Python versions, other weewx versions, and a
`paho-mqtt==1.6.1` job. Those need the workflow itself; use
[ACT](../actions/running-locally/) or `runworkflow.sh` for them.
