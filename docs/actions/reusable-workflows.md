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
By default it runs agains the 'latest' OS, Python and WeeWX versions.
By default it will run code coverage but not invoke any of the analysis 'providers'.

### analyze-test-matrix

A 'wrapper' for the perform-analyze-test workflow that runs the steps against a matrix of OS and Python versions with the 'latest' WeeWX version.
It will run code coveraage and invoke the analysis 'providers' when the matrix invocation is with the 'latest' OS and Python versions.

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

### Shared config files

The lint and coverage settings live in `development-tools/config` and are copied into each
repository. Before linting, the workflow compares the repository's `.pylintrc`, `.flake8`,
`.coveragerc`, and `requirements.txt` with the canonical copies at `config-ref` (default `v6`),
so a stale copy fails the build. If the ref has no `config` directory, the check is skipped.

## Reusable workflows to manage repositories

### stale

A workflow that will mark 'inactive' issues as stale.
If there is no activity against the stale issue, it will be closed.

### versioning

Create and keep up to date tags for `@latest` and for `@Vx`, where x is the major version number of `x.y.x`.
