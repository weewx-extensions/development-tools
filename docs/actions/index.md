---
title: GitHub Actions
has_children: true
has_toc: true
nav_order: 4
---

explain the  `.github/workflow` directory

analyze-test-matrix.yml
analyze-test.yml
fetch.yml
local-analyze-test-matrix.yml
local-analyze-test.yml
stale.yml
versioning.yml



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