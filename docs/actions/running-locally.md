---
title: Using ACT to run locally
parent: GitHub Actions
#has_children: true
#has_toc: true
nav_order: 4
---

## Using ACT and GitHub Local Actions VS Code Extension

options -> artifact-server-path = act-artifacts

add act-artifacts to .gitignore

remember to select it

Failure to do so will give a message similar to

``` text
::error::Unable to get the ACTIONS_RUNTIME_TOKEN env variable
```

Running locally with UBUNTU 22.04 and Pythone 3.9.13 will give the following error
[run-2/Perform the analysis and test/ubuntu-22.04 3.9.13 5.2.0] python: /lib/x86_64-linux-gnu/libm.so.6: version `GLIBC_2.38' not found (required by /opt/hostedtoolcache/Python/3.9.13/x64/lib/libpython3.9.so.1.0)
