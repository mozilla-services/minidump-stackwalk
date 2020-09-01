#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.
#
# This runs minidump-stackwalk just like it runs in the Socorro processor. This
# will help debug minidump-stackwalk problems.
#
# This requires you have raw crash and minidump data in ./crashdata_mdsw_tmp .
# Use crashstats-tools to get this data: https://github.com/willkg/crashstats-tools
#
# Usage:
#
#    app@socorro:/app$ ./bin/run_mdsw.sh [CRASHID]

set -e

DATADIR=./crashdata_mdsw_tmp
OUTPUTDIR=./outdir
SYMBOLS_URL="https://symbols.mozilla.org/"
STACKWALKER_PATH="/stackwalk/stackwalker"

if [[ $# -eq 0 ]]; then
    if [ -t 0 ]; then
        # If stdin is a terminal, then there's no input
        echo "Usage: run_mdsw.sh CRASHID"
        exit 1
    fi

    # stdin is not a terminal, so pull the args from there
    set -- ${@:-$(</dev/stdin)}
fi

if [ ! -d "${DATADIR}" ]; then
    echo "You need raw crash data and minidumps in ./crashdata_mdsw_tmp ."
    exit 1
fi

mkdir -p /tmp/symbols/cache || true
mkdir -p /tmp/symbols/tmp || true
mkdir -p ${OUTPUTDIR} || true

for CRASHID in "$@"
do
    # Find the raw crash file
    RAWCRASHFILE=${DATADIR}/raw_crash/${CRASHID}
    DUMPFILE=${DATADIR}/upload_file_minidump/${CRASHID}

    timeout -s KILL 600 "${STACKWALKER_PATH}" \
        --raw-json ${RAWCRASHFILE} \
        --symbols-url "${SYMBOLS_URL}" \
        --symbols-cache /tmp/symbols/cache \
        --symbols-tmp /tmp/symbols/tmp \
        ${DUMPFILE} > ${OUTPUTDIR}/${CRASHID}.json
done
