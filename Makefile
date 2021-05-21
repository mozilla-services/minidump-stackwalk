# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.

# Include .env and export it so variables set in there are available
# in the Makefile.
include .env
export

# Set these in the environment to override them. This is helpful for
# development if you have file ownership problems because the user in the
# container doesn't match the user on your host.
USER_ID ?= 10001
GROUP_ID ?= 10001

# Set this in the environment to force --no-cache docker builds.
DOCKER_BUILD_OPTS :=
ifeq (1, ${NOCACHE})
DOCKER_BUILD_OPTS := --no-cache
endif

DC := $(shell which docker-compose)

.DEFAULT_GOAL := help
.PHONY: help
help:
	@echo "Usage: make RULE"
	@echo ""
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' Makefile \
		| grep -v grep \
	    | sed -n 's/^\(.*\): \(.*\)##\(.*\)/\1\3/p' \
	    | column -t  -s '|'
	@echo ""
	@echo "See https://github.com/mozilla-services/minidump-stackwalk/ for more documentation."

.env:
	@if [ ! -f .env ]; \
	then \
	echo "Creating .env ..."; \
	echo "# USER_ID=\n# GROUP_ID=\n" > .env; \
	fi

.docker-build:
	make build

.PHONY: build
build: .env  ## | Build docker images.
	${DC} build --build-arg USER_ID=${USER_ID} --build-arg GROUP_ID=${GROUP_ID} app
	touch .docker-build

.PHONY: shell
shell: .env .docker-build  ## | Open a shell in the app container.
	${DC} run --rm app bash

.PHONY: clean
clean:  ## | Remove all build artifacts.
	-rm .docker-build*
	./bin/clean_artifacts.sh
	-rm -rf tmp

sizeof: .env .docker-build  ## | Size of minidump_stackwalker docker image.
	docker images | grep minidump
