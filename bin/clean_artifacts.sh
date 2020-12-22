#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Delete build artifacts from building breakpad and minidump-stackwalker

find pgo_data -name "*.extra" -exec rm -f {} \;
find pgo_data -name "*.dmp" -exec rm -f {} \;
find pgo_data -name "*.sym" -exec rm -f {} \;
rm -rf build breakpad stackwalk google-breakpad breakpad.tar.gz depot_tools
rm -rf .cache
rm -rf mdsw_venv
cd minidump-stackwalk && make clean
