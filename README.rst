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


minidump-stackwalk output
=========================


JSON output
-----------

Rough JSON output schema:

::

  {
    "status": <string>,                      // OK | ERROR_* | SYMBOL_SUPPLIER_INTERRUPTED
    "system_info": {
      "os": <string>,                        // Linux | Windows NT | Mac OS X
      "os_ver": <string>,
      "cpu_arch": <string>,                  // x86 | amd64 | arm | ppc | sparc
      "cpu_info": <string>,
      "cpu_count": <int>,
      "cpu_microcode_version": <int>         // optional
    },
    "crash_info": {
      "type": <string>,
      "crash_address": <string>,             // 0x[[:xdigit:]]+, optional
      "crashing_thread": <int>,              // thread index | null; optional
      "assertion": <string>                  // optional
    }
    "largest_free_vm_block": <string>,       // 0x[[:xdigit:]]+
    "lsb_release": {                         // this section is optional and covers Linux Standard Base information
      "id": <string>,
      "release": <string>,
      "codename": <string>,
      "description": <string>
    },
    "main_module": <int>,                    // index of module in modules list
    "modules_contain_cert_info": true,       // optional
    "modules": [
      // zero or more
      {
        "base_addr": <string>,               // 0x[[:xdigit:]]+
        "debug_file": <string>,              // filename | empty string
        "debug_id": <string>,                // [[:xdigit:]]{33} | empty string
        "end_addr": <string>,                // 0x[[:xdigit:]]+
        "filename": <string>,
        "code_id": <string>,
        "version": <string>,
        "loaded_symbols": true,              // optional, if mdsw looked for the file and it does exist
        "missing_symbols": true,             // optional, if mdsw looked for the file and it doesn't exist
        "corrupt_symbols": true,             // optional, if mdsw found a file that has parse errors
        "symbol_disk_cache_hit": <bool>,     // optional, whether or not the SYM file was fetched from disk cache
        "symbols_fetch_time": <float>,       // optional, time in ms it took to fetch symbol file from url; omitted
                                             // if the symbol file was in disk cache
        "symbol_url": <string>,              // optional, url of symbol file
        "cert_subject": ?                    // optional
      }
    ],
    "pid": <int>,                            // pid of crashed process
    "thread_count": <int>,
    "threads": [
      // for i in range(thread_count)
      {
        "frame_count": <int>,
        "frames_truncated": true,            // optional
        "total_frames": <int>,               // if truncated, this is the original total; optional
        "last_error_value": <string>,        // optional
        "thread_name": <string>,             // optional
        "frames": [
          // for i in range(frame_count)
          {
            "frame": <int>,                  // frame index; 0-based
            "module": <string>,              // optional
            "function": <string>,            // optional
            "file": <string>,                // optional
            "line": <int>,                   // optional
            "offset": <string>,              // 0x[[:xdigit:]]+
            "module_offset": <string>,       // 0x[[:xdigit:]]+ , optional
            "function_offset": <string>      // 0x[[:xdigit:]]+ , optional
            "missing_symbols": true,         // optional
            "corrupt_symbols": true,         // optional
            "trust": <string>,               // none | scan | cfi_scan | frame_pointer | cfi | context | prewalked

            "registers": {                   // this section is frame 0 only, optional
              // for each register
              <string>: <string>,            // name is a register name and is architecture-dependent;
                                             // value is 0x[[:xdigit:]]
            }
          }
        ]
      }
    ],
    "tiny_block_size": <int>,
    "write_combine_size": <int>,

    "unloaded_modules": [
      // for i in range(unloaded_modules_count)
      {
        "base_addr": <string>,               // 0x[[:xdigit:]]+
        "code_id": <string>,
        "end_addr": <string>,                // 0x[[:xdigit:]]+
        "filename": <string>
      }
    ],
    
    // this is a repeat of the crashing thread in the threads list, but the
    // number of frames is truncated to 10
    "crashing_thread": {
      "threads_index": <int>,                // index in threads for the crashing thread
      "total_frames": <int>,                 // total frames in list
      "thread_name": <string>,               // optional
      "frames": [
        // for i in range(frame_count)
        {
          // as per "frames" entries from "threads" above
        }
      ]
    },

    "mac_crash_info": {                      // optional section
      "num_records": <int>,                  // number of crash info records
      "records": [
        // for i in range(mac_crash_info_count)
        {
          "module": <string>,                // optional
          "message": <string>,               // optional
          "signature_string": <string>,      // optional
          "backtrace": <string>,             // optional
          "message2": <string>,              // optional
          "thread": <string>,                // 0x[[:xdigit:]], optional
          "dialog_mode": <string>,           // 0x[[:xdigit:]], optional
          "abort_cause": <string>            // 0x[[:xdigit:]], optional
        }
      ]
    },

    "sensitive": {
      "exploitable": <string>                // low | medium | high | interesting | none | ERROR: *
    }
  }


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
