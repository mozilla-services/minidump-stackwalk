FROM debian:buster-slim@sha256:b2cade793f3558c90d018ed386cd61bf5e4ec06bf8ed6761bed3dd7e2c425ecc

# Set up user and group
ARG USER_ID=10001
ARG GROUP_ID=10001

RUN groupadd --gid $GROUP_ID app && \
    useradd -g app --uid $USER_ID --shell /usr/sbin/nologin --create-home app

WORKDIR /app/

# Copy everything over
COPY . /app/

# Install breakpad requirements and some helpful debugging things
RUN apt-get update && \
    apt-get install -y apt-transport-https && \
    apt-get install -y \
        build-essential \
        git \
        gdb \
        libcurl4 \
        libcurl3-gnutls \
        libcurl4-gnutls-dev \
        pkg-config \
        python2 \
        rsync \
        vim \
        wget && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /stackwalk

# Build and then remove the artifacts to keep the image from ballooning
RUN STACKWALKDIR=/stackwalk bin/build_stackwalker.sh && \
    bin/clean_artifacts.sh

# Let app own /app and /stackwalk so it's easier to debug later
RUN chown -R app:app /app /stackwalk

USER app
