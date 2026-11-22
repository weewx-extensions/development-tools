#!/usr/bin/env python

import os
import signal
import subprocess

home = os.environ['HOME']
REPOS_DIR = f'{home}/weewx_code/'
WEEWX_DIR = f'{home}/weewx/'
TIMEOUT = 30

repos = ['weewx-gw1000',
         'WeeWX-Extras',

         'forks/vds-weewx-v3-mem-extension',
         'forks/weewx-cmon',
         'forks/weewx-celestial',
         'forks/weewx-loopdata',
         'forks/weewx-nws',
         'forks/weewx-skyfield',

         'weewx-extensions/aqi-xtype',
         'weewx-extensions/development-tools',
         'weewx-extensions/healthchecks',
         'weewx-extensions/jas',
         'weewx-extensions/pushover',

         'weewx-mqtt/mqttcommon',
         'weewx-mqtt/plugin-loopdata',
         'weewx-mqtt/publish',
         'weewx-mqtt/replicate',
         'weewx-mqtt/subscribe',

         'configs',
         'secrets']


def run(command, cwd):
    try:
        process = subprocess.Popen(command, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, cwd=cwd,
                                   start_new_session=True)
    except FileNotFoundError:
        return None
    try:
        output, errors = process.communicate(timeout=TIMEOUT)
    except subprocess.TimeoutExpired:
        # git's ssh child outlives a bare process.kill(), so kill the whole group.
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.communicate()
        return f'TIMED OUT after {TIMEOUT}s'
    text = output.decode('utf-8', errors='replace').strip()
    if errors.strip():
        detail = errors.decode('utf-8', errors='replace').strip()
        text = '\n'.join(part for part in (text, detail) if part)
    return text


def show(command, targets):
    print(f'\nRunning command: {" ".join(command)}')
    for label, cwd, report_missing in targets:
        text = run(command, cwd)
        if text is None:
            if report_missing:
                print(f'{label} does not exist')
        else:
            print(f'{label}: {text}')


targets = [('weewx', WEEWX_DIR, True)]
targets += [(repo, f'{REPOS_DIR}{repo}', False) for repo in repos]

show(['git', 'fetch', '--quiet'], targets)
show(['git', 'status', '--branch', '-uno', '--null'], targets)
show(['git', 'log', '--format=format:"%ci %h %d %s"', '-n 1'], targets)

print("\nFor more information run the following commands from the repository directory.")
print('  git log HEAD..origin --format="format:%ci %h %d %s"')
print('  git diff HEAD...origin/master')
