#!/bin/bash
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

# Build script for building Breakpad
#
# Generally run in Taskcluster, but split out to a separate script so it can be
# run for local builds if necessary without assuming the Taskcluster
# environment.

set -euxo pipefail

# Build the revision used in the snapshot unless otherwise specified.
# Update this if you update the snapshot!
: BREAKPAD_REV         "${BREAKPAD_REV:=78f7ae495bc147e97a58e8158072fd35fdd99419}"

# Locate the local patches
BREAKPAD_PATCHES="$(pwd)/breakpad-patches"

export MAKEFLAGS
MAKEFLAGS=-j$(getconf _NPROCESSORS_ONLN)

if [ ! -d "depot_tools" ]; then
  git clone --depth=1 --single-branch https://chromium.googlesource.com/chromium/tools/depot_tools.git
fi

cd depot_tools || exit
git pull origin master
echo ">>> using depot_tools version: $(git rev-parse HEAD)"
cd ..

# Breakpad will rely on a bunch of stuff from depot_tools, like fetch
# so we just put it on the path
# see https://chromium.googlesource.com/breakpad/breakpad/+/master/#Getting-started-from-master
export PATH
PATH=$(pwd)/depot_tools:$PATH

# depot_tools only works if Python 2 is "python", but the python2 package
# in buster installs it as /usr/bin/python2, so we link it.
if [ ! -h /usr/bin/python ]; then
    ln -s /usr/bin/python2 /usr/bin/python
fi

# Checkout and build Breakpad
echo "PREFIX: ${PREFIX:=$(pwd)/build/breakpad}"
if [ ! -d "breakpad" ]; then
  mkdir breakpad
  cd breakpad
  fetch breakpad
else
  cd breakpad/src
  git fetch origin
  cd ..
fi

cd src
git checkout --force "$BREAKPAD_REV"
gclient sync

echo ">>> using breakpad version: $(git rev-parse HEAD)"

pwd
# Apply local patches
for p in ${BREAKPAD_PATCHES}/*.patch; do
    echo "Applying $p"
    if ! cat $p | patch -p1; then
      echo "Failed to apply $p"
      exit 1
    fi
done

mkdir -p "${PREFIX}"
rsync -a --exclude="*.git" ./src "${PREFIX}"/

# Configure breakpad for building
OPTFLAGS="-O3 -flto ${PGOFLAGS} -Wno-coverage-mismatch -Wno-missing-profile"
CFLAGS="${OPTFLAGS}" CXXFLAGS="${OPTFLAGS}" ./configure --prefix="${PREFIX}" || grep "error:" config.log

CPU_NUM=$(grep ^processor /proc/cpuinfo  | wc -l)
make -j${CPU_NUM} install
# if [ -z "${SKIP_CHECK}" ]; then
#   #FIXME: get this working again
#   make check
# fi
git rev-parse HEAD > "${PREFIX}"/revision.txt
cd ../..

cp breakpad/src/src/third_party/libdisasm/libdisasm.a "${PREFIX}"/lib/

# Optionally package everything up
if [ -z "${SKIP_TAR}" ]; then
  tar -C "${PREFIX}"/.. -zcf breakpad.tar.gz "$(basename "${PREFIX}")"
fi
