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

# Failures in this script should cause the build to fail
set -v -e -x

# Build the revision used in the snapshot unless otherwise specified.
# Update this if you update the snapshot!
: BREAKPAD_REV         "${BREAKPAD_REV:=216cea7bca53fa441a3ee0d0f5fd339a3a894224}"

export MAKEFLAGS
MAKEFLAGS=-j$(getconf _NPROCESSORS_ONLN)

if [ ! -d "depot_tools" ]; then
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
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
ln -s /usr/bin/python2 /usr/bin/python

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
git checkout "$BREAKPAD_REV"
gclient sync

echo ">>> using breakpad version: $(git rev-parse HEAD)"

mkdir -p "${PREFIX}"
rsync -a --exclude="*.git" ./src "${PREFIX}"/

# NOTE(willkg): Swap these when you're building a pgo profile
export PGOFLAGS="-fprofile-use=/app/pgo_profile/"
# export PGOFLAGS="-fprofile-generate=/app/pgo_profile/"

# Configure breakpad for building
export CXXFLAGS="-g -flto -O3 ${PGOFLAGS}"
./configure --prefix="${PREFIX}"

make install
if [ -z "${SKIP_CHECK}" ]; then
  #FIXME: get this working again
  #make check
  true
fi
git rev-parse HEAD > "${PREFIX}"/revision.txt
cd ../..

cp breakpad/src/src/third_party/libdisasm/libdisasm.a "${PREFIX}"/lib/

# Optionally package everything up
if [ -z "${SKIP_TAR}" ]; then
  tar -C "${PREFIX}"/.. -zcf breakpad.tar.gz "$(basename "${PREFIX}")"
fi
