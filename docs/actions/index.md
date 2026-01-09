---
title: GitHub Actions
has_children: true
has_toc: true
nav_order: 3
---

explain the  `.github/workflow` directory

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
