---
title: Directory Structure
parent: Overview
nav_order: 1
---

The tools providedk by this repository expect a directory that is like the following.
All of the GitHub organizations, and therefore repositories, are under a single directory.
In this case the directory is named, `weewx_dev`.
But the name could be anything.

Directly under this directory are any GitHub organizations using tooling provided by this repository.

Also directly under is a directory of WeeWX releases.
These releases are used to test the extensions with different versions of WeeWX.

``` text
~/weewx_dev
├── weewx-extensions
│   ├── aqi-xtype
│   ├── development-tools
│   ├── healthchecks
│   ├── jas
│   ├── pushover
│   ├── weewx -> weewx-5.1.0
│   ├── weewx-5.0.0 -> ../weewx-releases/weewx-5.0.0
│   ├── weewx-5.0.1 -> ../weewx-releases/weewx-5.0.1
│   ├── weewx-5.0.2 -> ../weewx-releases/weewx-5.0.2
│   ├── weewx-5.1.0 -> ../weewx-releases/weewx-5.1.0
│   └── wikis
├── weewx-mqtt
│   ├── publish
│   ├── replicate
│   ├── subscribe
│   ├── weewx -> weewx-5.1.0
│   ├── weewx-5.0.0 -> ../weewx-releases/weewx-5.0.0
│   ├── weewx-5.0.1 -> ../weewx-releases/weewx-5.0.1
│   ├── weewx-5.0.2 -> ../weewx-releases/weewx-5.0.2
│   ├── weewx-5.1.0 -> ../weewx-releases/weewx-5.1.0
│   └── wikis
└── weewx-releases
    ├── weewx-fork
    ├── weewx-4.10.0
    ├── weewx-4.10.1
    ├── weewx-4.10.2
    ├── weewx-4.6.1
    ├── weewx-4.7.0
    ├── weewx-4.8.0
    ├── weewx-4.9.0
    ├── weewx-5.0.0
    ├── weewx-5.0.1
    ├── weewx-5.0.2
    └── weewx-5.1.0
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
|── changes.txt
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
