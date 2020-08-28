FROM python:3.8.5-slim@sha256:9c84459051ee7e9d386b24ee5468352d52b6789a5d4a8cf6a649a8a1c6ad5636

# Set up user and group
ARG USER_ID=10001
ARG GROUP_ID=10001

WORKDIR /app/
RUN groupadd --gid $GROUP_ID app && \
    useradd -g app --uid $USER_ID --shell /usr/sbin/nologin --create-home app && \
    chown app:app /app/

WORKDIR /app/

# Copy everything over
COPY --chown=app:app . /app/

# Install breakpad requirements and some helpful debugging things
RUN apt-get update && apt-get install -y \
    gdb \
    libcurl4 \
    libcurl3-gnutls \
    libcurl4-gnutls-dev \
    pkg-config \
    rsync \
    vim \
    wget \
&& rm -rf /var/lib/apt/lists/*

RUN /app/bin/build-stackwalker.sh

# Let app own /app and /stackwalk so it's easier to debug later
RUN chown -R app:app /app /stackwalk

USER app
