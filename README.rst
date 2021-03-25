====================
minidump-stackwalker
====================

This repo holds the stackwalker binaries that parse minidump files that Socorro
uses.


Docker images
=============

Docker images with the breakpad and stackwalk binaries are at:

https://hub.docker.com/r/mozilla/socorro-minidump-stackwalk

The ``latest`` tag covers whatever is in the main branch.

The other tags in the form of ``YYYY.MM.DD`` were tagged that day. See tag
comments for changes.


Usage
=====

dumplookup
----------

FIXME(willkg): Document this.

For help, do::

  $ dumplookup --help


stackwalker
-----------

Parses the minidump and spits out information about the crash, crashing thread,
and stacks.

Example::

  $ stackwalker --pretty <MINDUMPFILE>


For help, do::

  $ stackwalker --help


jit-crash-categorize
--------------------

States whether the minidump represents a JIT crash.

Example::

  $ jit-crash-categorize <MINIDUMPFILE>


To build
========

::

    $ make build


Build scripts
=============

The stackwalker binaries get built in the local development environment and live
in the app image in ``/stackwalk``.

If you want to build them outside of Docker, you can use these two build
scripts:

* ``bin/build_breakpad.sh``

  This will build breakpad from source and place the resulting bits in
  ``./build/breakpad``.

* ``bin/build_stackwalker.sh``

  This will build stackwalker.


Getting a shell for minidump-stackwalk
======================================

To get a shell to debug minidump-stackwalk, do::

    $ make shell

To run the build script, do::

    app@socorro:/app$ ./bin/build_stackwalker.sh

``vim`` and ``gdb`` are available in the shell.

Things to keep in mind:

1. It's pretty rough and there might be issues--let us know.
2. When you're done with the shell, it makes sense to run ``make clean`` to
   clean out any extra bits from minidump-stackwalk floating around.


PGO profile
===========

By default both minidump-stackwalk and breakpad are built with PGO and an
appropriate training set is included in the sources.


Release process
===============

The release process is mostly automated. It handles building Docker images and
pushing them to Docker Hub.

This is maintained by Socorro engineers and Socorro ops.


latest image
------------

To trigger building a new ``latest`` image:

1. Land something in the main branch

2. Wait for a bit and check https://hub.docker.com/r/mozilla/socorro-minidump-stackwalk
   to verify the new Docker image is there


release images
--------------

To trigger building a release image:

1. Run ``python bin/release.py make-tag``

   I run this Python 3.8 on my host--not in the Docker container shell. This
   should work with Python 3.6 and higher.

   This uses ``git`` to look at the repository state, so that needs to be
   installed. Make sure your ``main`` branch is up to date with what's on
   GitHub.

   In order for this to work, you need to have authority to push tags
   to GitHub.

   This will look at the previous tag, figure out what's changed since then,
   generate a tag name, generate a tag comment, create the tag, and push the
   tag.

2. Wait for a bit and check https://hub.docker.com/r/mozilla/socorro-minidump-stackwalk
   to verify the new Docker image is there


troubleshooting
---------------

minidump-stackwalk relases are done using CircleCI. Check the CircleCI builds for
problems: https://app.circleci.com/pipelines/github/mozilla-services/minidump-stackwalk
