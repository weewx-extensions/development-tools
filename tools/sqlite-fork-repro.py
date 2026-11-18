#! /usr/bin/env python3
#
#    Copyright (c) 2026 Rich Bell <bellrichm@gmail.com>
#
#    See the file LICENSE.txt for your full rights.
#
"""Reproduce the fork-after-SQLite SIGSEGV that Apple's libsqlite3 causes.

Usage:

    python3 sqlite-fork-repro.py                             # in-memory databases
    python3 sqlite-fork-repro.py --database ~/weather.sdb    # a real archive database

Each child opens a SQLite database after forking from a parent that has already
opened one. On an affected machine the child dies with SIGSEGV before it can say
anything:

    EXC_BAD_ACCESS (SIGSEGV) in libsqlite3.dylib -> openDatabase
      <- _sqlite3.cpython-3xx-darwin.so -> pysqlite_connection_init

Where it was seen: macOS 27.2.1 (build 26B8132, Darwin 27.2.0), arm64, with Apple's
libsqlite3 3.54.0 in the dyld shared cache. Binding _sqlite3 to Homebrew's sqlite 3.54.1
instead - build-pythons.sh next to this script - makes the same fork survive, so the fault is
in the OS library rather than in CPython or the application. Treat any macOS whose libsqlite3
matches as a candidate.

What this shows:

- It is not WeeWX, weewx-mqtt or the plugin's code: only sqlite3 and
  multiprocessing are involved.
- It is not an inherited connection and not a lock: whether the parent's
  connection is open, closed, or fails to open makes no difference. The child only
  has to open a database after the fork.
- The outcome is decided per process, not per fork: every child of one parent
  either crashes or none does (address space layout). Which parent process crashes
  is random, so a version or setup that worked a moment ago can fail after a
  restart - which is why this looked like an intermittent hang, not a crash.
- It is not one Python version. Observed with the pyenv builds 3.9.13, 3.10.22,
  3.14.10 and 3.15.2 and with the system 3.9.6, all linking the same
  /usr/lib/libsqlite3.dylib (3.54.0) on macOS 27.2.1. Only the frequency differs:
  in a sample of ten parent processes (three forks each) 3.10.22 crashed in 2,
  3.9.13 in 6, 3.14.10 in 9 and 3.15.2 in 10. None is safe; 3.10 is the least bad.
- The same crash takes down any forked process that touches SQLite, not just one
  application: WeeWX opens its database manager in a forked publishing worker too.

Exit status: 0 when every child survived, 1 when any child died, 2 when one hung,
so it can be run in a loop to compare interpreters.
"""

import argparse
import multiprocessing
import os
import sqlite3
import sys


def parse_args():
    """ The command line. """
    parser = argparse.ArgumentParser(description="Open SQLite in forked children.")
    parser.add_argument('--database',
                        help="a SQLite file the parent and the children open, instead of ':memory:'")
    parser.add_argument('--trials', type=int, default=5, help="how many children to fork")
    return parser.parse_args()


def child(queue, database):
    """ Open a database in the child, and report what happened. """
    try:
        connection = sqlite3.connect(database)
        connection.execute('select 1').fetchone()
        queue.put('opened')
    except BaseException as exception:  # pylint: disable=broad-exception-caught
        queue.put(repr(exception))


def main():
    """ Fork, open, report. """
    args = parse_args()
    database = os.path.expanduser(args.database) if args.database else ':memory:'

    # The parent uses SQLite the way WeeWX does: a connection that is still open when
    # the worker forks.
    parent = sqlite3.connect(database)
    parent.execute('select 1').fetchone()

    print(f"Python {sys.version.split()[0]}, sqlite3 {sqlite3.sqlite_version}, database {database}")

    context = multiprocessing.get_context('fork')
    queue = context.Queue()
    exit_codes = []

    for trial in range(args.trials):
        process = context.Process(target=child, args=(queue, database))
        process.start()
        process.join(30)
        if process.is_alive():
            print(f"  trial {trial}: HUNG")
            process.terminate()
            process.join(5)
            exit_codes.append('hung')
            continue

        result = 'no result'
        try:
            result = queue.get(timeout=5)
        except Exception:  # pylint: disable=broad-exception-caught
            pass
        print(f"  trial {trial}: exit code {process.exitcode} ({result})")
        exit_codes.append(process.exitcode)

    if 'hung' in exit_codes:
        return 2
    return 0 if all(exit_code == 0 for exit_code in exit_codes) else 1


if __name__ == '__main__':
    sys.exit(main())
