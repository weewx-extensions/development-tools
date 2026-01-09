---
title: GitHub Actions
has_children: true
has_toc: true
nav_order: 4
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

### versioning

### run locally

options -> artifact-server-path = act-artifacts
add act-artifacts to .gitignore
remember to selectd it

### These probably belong on a separate page

#### run coveralls

sign into coveralls.io
Navigate to add repos
Turn the repo on

run codecov
sign into codecov.io
navigate to correct organization
select 'configure' for the correct repo
use github actions
language = pytest
select repo token
copy token
in github, goto repo settings ->secrets and variables -> actions
new repository secret = 'CODECOV_TOKEN'
use token from codecov.io

upload to sonar cloud
sign into sonarcloud.io
top right, select "+" (analyze a new project)
select the github repo
select "setup"
new code -> previous version -> create project

on sonarcloud.io, select the new project
lower left, select "administration -> analysis method"
disable 'automatic'
add token to repo on gthub
in github, goto repo settings ->secrets and variables -> actions
new repository secret = 'SONAR_TOKEN'
add sonar-project.properties to github
be sure to set organization and key
