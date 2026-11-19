---
title: Directory Structure
parent: Overview
nav_order: 1
---

The tools provided by this repository expect a directory that is like the following.
This is an example of the shape, not a fixed list: the repositories and releases the tools
look for are named by the arrays in `tools/setup.sh` (`ROOT_REPOS`, `FORK_REPOS`,
`EXTENSION_REPOS`, `MQTT_REPOS` and `WEEWX_VERSIONS`), which are the definitive content.

All of the GitHub organizations, and therefore repositories, are under a single directory.
In this case the directory is named, `weewx_code`.
But the name could be anything.

Directly under this directory are any GitHub organizations using tooling provided by this repository.

Also directly under is a directory of WeeWX releases.
These releases are used to test the extensions with different versions of WeeWX.

``` text
~/weewx_code
├── WeeWX-Extras
├── configs
├── secrets
├── forks
├── weewx-extensions
│   ├── aqi-xtype
│   ├── development-tools
│   ├── healthchecks
│   ├── jas
│   ├── pushover
│   └── test
├── weewx-mqtt
│   ├── mqttcommon
│   ├── plugin-loopdata
│   ├── publish
│   ├── replicate
│   ├── subscribe
│   ├── weewx-fork -> ../weewx-releases/weewx-fork
│   └── weewx -> weewx-fork
└── weewx-releases
    ├── weewx-clone
    ├── weewx-fork
    ├── weewx-5.5.2
    └── weewx-5.0.0
```

A typical extension directory structure would look like this.

```text
.
├── bin
│   └── user
│       └── tests
│           ├── e2e
│           ├── func
│           ├── integ
│           └── unit
├── changes.txt
├── codecov.yml
├── .coverage
├── .coveragerc
├── .devenv
├── docs
├── .env
├── .flake8
├── .git
├── .github
├── .gitignore
├── htmlcov
├── install.py
├── LICENSE
├── .markdownlint.json
├── notes.md
├── .pylintrc
├── .pytest.ini
├── README.md
├── sonar-project.properties
├── tmp
├── .vscode
```
