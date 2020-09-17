====================
minidump-stackwalker
====================

This repo holds the stackwalker binaries that parse minidump files that Socorro
uses.


Docker image
============

Docker images with the breakpad and stackwalk binaries are at:

https://hub.docker.com/r/mozilla/socorro-minidump-stackwalk


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

This is clunky--sorry!

To build a PGO profile:

1. swap the ``PGOFLAGS`` lines to ``-fprofile-generate`` in
   ``minidump-stackwalk/Makefile`` and ``bin/build-breakpad.sh``
2. run ``make clean`` and ``make build``
3. process 100 crash reports
4. the profile should be in ``/app/pgo_profile/`` in the container and ``./pgo_profile/``
   outside the container
5. swap the ``PGOFLAGS`` lines back to ``-fprofile-use``
6. commit profile to git
