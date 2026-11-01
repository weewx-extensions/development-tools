---
title: Reusable Workflows
parent: GitHub Actions
#has_children: true
#has_toc: true
nav_order: 1
---

## Reusable workflows for analyzing and testing code

### perform-analyze-test

This workflow performs all the code analysis and test steps.
It needs to be 'wrapped' with a workflow that passes in the necessary parameters.

### analyze-test

A 'wrapper' for the perform-analyze-test workflow that runs the steps against a single OS version, Python version, and WeeWX version.
By default it runs against the 'latest' OS, Python and WeeWX versions.
By default it runs code coverage and uploads it to Codacy; Coveralls, Codecov, and Sonar are off.

### analyze-test-matrix

A 'wrapper' for the perform-analyze-test workflow that runs the steps against a matrix of OS and Python versions with the 'latest' WeeWX version.
It will run code coverage and invoke the analysis 'providers' when the matrix invocation is with the 'latest' OS and Python versions.

### Required WeeWX extensions

`weewx-extensions` lists the extensions the module needs, one per line, as `<url> [version]`.
The version defaults to `master`; any other value is a release tag, without the `v`.

```yaml
    with:
      weewx-extensions: |
        https://github.com/chaunceygardiner/weewx-loopdata/ 7.0
        https://github.com/weewx-mqtt/publish/
```

The extensions are installed into the station before the checkout under test, so a module
can use another extension's modules without shipping a copy.
`weewx-extension` and `weewx-extension-ver` still install a single extension.

### Upload tokens

`CODECOV_TOKEN`, `CODACY_API_TOKEN`, and `SONAR_TOKEN` are optional. A provider whose `*-upload`
input is on but whose token is empty gets a warning annotation and its upload is skipped, so a
repository that only uses one provider does not have to hold secrets for the others.

### Shared config files

The lint and coverage settings live in `development-tools/config` and are copied into each
repository. Before linting, the workflow compares the repository's `.pylintrc`, `.pylintrc-tests`,
`.flake8`, `.coveragerc`, `.codacy.yaml`, and `requirements.txt` with the canonical copies at `config-ref`
(default `v6`), so a stale copy fails the build. If the ref has no `config` directory, the check
is skipped.

The tests are linted too, using `.pylintrc-tests`, when the repository has a `bin/user/tests`
directory.

### Shared common module

`mqttcommon.py` is copied in from
[weewx-mqtt/mqttcommon](https://github.com/weewx-mqtt/mqttcommon) rather than edited here. The
workflow compares `bin/user/mqttcommon.py` and `bin/user/tests/unit/test_mqttcommon.py` with
`common-ref` (default `v1`), so a stale or hand-edited copy fails the build. If the repository
does not vendor the module, or the ref is not available, the check is skipped. Locally, the same
comparison is `mqttcommon.sh --check`.

### Workflow lint

The workflow files are linted with [actionlint](https://github.com/rhysd/actionlint), which also hands
each `run:` block to shellcheck. The script and the actionlint release it pins come from `config-ref`,
the same ref as the config files, so a local run and CI agree. The check runs on the latest matrix cell
only, and is skipped when the ref has no `tools/actionlint.sh`. Locally, `verify.sh` runs the same
script.

## Bringing a repository up to date

1. Workflows: copy the files from `workflows-template`, set `module-name` and the test flags, or run
   `refs.sh` to move the existing refs to the current major version.
2. Shared configs: `configs.sh` copies `.pylintrc`, `.pylintrc-tests`, `.flake8`, `.coveragerc`,
   `.codacy.yaml`, and `requirements.txt` from `development-tools/config`.
3. Local environment: copy `.devenv-template` to `.devenv` and set `WEEWX_MODULE_NAME`.
4. `verify.sh` runs the same checks as CI: the environment, pylint and flake8, actionlint, the
   workflow refs, the config copies, and the tests.

## Reusable workflows to manage repositories

### stale

A workflow that will mark 'inactive' issues as stale.
If there is no activity against the stale issue, it will be closed.

### versioning

Create and keep up to date tags for `@latest` and for `@Vx`, where x is the major version number of `x.y.x`.
