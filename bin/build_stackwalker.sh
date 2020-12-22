#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Build script for building Breakpad and stackwalker

# Failures should cause setup to fail
set -v -e -x

# Destination directory for the final stackwalker binaries
STACKWALKDIR="${STACKWALKDIR:-$(pwd)/stackwalk}"

# Source and build directories
SRCDIR="${SRCDIR:-$(pwd)}"

cd "${SRCDIR}"

# Build breakpad from source; instrument code for profile generation
export PGOFLAGS="-fprofile-generate=/app/pgo_profile/"
PREFIX="${SRCDIR}/breakpad/" SKIP_TAR=1 "${SRCDIR}/bin/build_breakpad.sh"

# Copy breakpad bits into stackwalk/ to compile minidump-stackwalker
rm -rf stackwalk || true
cp -r "${SRCDIR}/breakpad" "${SRCDIR}/stackwalk"

# Now build the instrumented stackwalker
cd "${SRCDIR}/minidump-stackwalk"
CPU_NUM=$(grep ^processor /proc/cpuinfo  | wc -l)
make -j${CPU_NUM}

# Do a profile run
cd ..
find pgo_data -type f -name "*.xz" -exec xz -d --keep {} \;
PGO_SAMPLES="
android-aarch64
android-arm
linux-x86_64
linux-x86
macos-x86_64
windows-aarch64
windows-x86
windows-x86_64
"

for i in $PGO_SAMPLES; do
  minidump-stackwalk/stackwalker --raw-json "pgo_data/minidumps/${i}.extra" \
    "pgo_data/minidumps/${i}.dmp" pgo_data/symbols 1>/dev/null 2>/dev/null
done

# Rebuild breakpad with PGO data
rm -rf breakpad
export PGOFLAGS="-fprofile-use=/app/pgo_profile/"
PREFIX="${SRCDIR}/breakpad/" SKIP_TAR=1 "${SRCDIR}/bin/build_breakpad.sh"

# Copy breakpad bits into stackwalk/ to compile minidump-stackwalker
rm -rf stackwalk || true
cp -r "${SRCDIR}/breakpad" "${SRCDIR}/stackwalk"

# Now rebuild the stackwalker with PGO data
cd "${SRCDIR}/minidump-stackwalk"
make clean
make -j${CPU_NUM}

# Put the final binaries in STACKWALKDIR
if [ ! -d "${STACKWALKDIR}" ];
then
  mkdir "${STACKWALKDIR}"
fi
cd "${SRCDIR}/breakpad/bin/"
cp * "${STACKWALKDIR}"
cd "${SRCDIR}/minidump-stackwalk/"
cp stackwalker jit-crash-categorize dumplookup "${STACKWALKDIR}"
