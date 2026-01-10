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

## Reusable workflows to manage repositories

### stale

A workflow that will mark 'inactive' issues as stale.
If there is no activity against the stale issue, it will be closed.

### versioning

Create and keep up to date tags for `@latest` and for `@Vx`, where x is the major version number of `x.y.x`.
