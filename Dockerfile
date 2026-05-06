# Edge Cloud Platform - Docker Development Environment
#
# This Dockerfile provides a hardened development environment for working with
# the edge cloud platform tooling. It is not a production MicroCloud runtime.
#
# Build: docker build -t edge-cloud-platform .
# Run:   docker run -it edge-cloud-platform bash

FROM ubuntu:22.04

LABEL org.opencontainers.image.title="Edge Cloud Platform Development Environment" \
      org.opencontainers.image.description="Hardened development tooling image for the MicroCloud edge platform" \
      org.opencontainers.image.licenses="Apache-2.0"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG DEBIAN_FRONTEND=noninteractive
ARG USER_NAME=developer
ARG USER_UID=10001
ARG USER_GID=10001

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/opt/ansible/bin:${PATH}" \
    EDITOR=vim

# Install only required packages in a single layer and avoid recommended extras.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    iputils-ping \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    snapd \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Configure snapd for development (using classic confinement)
# Note: Snap inside Docker may have limitations

# Install Ansible tooling into an isolated virtual environment instead of the
# system Python environment.
RUN python3 -m venv /opt/ansible \
    && /opt/ansible/bin/pip install --no-cache-dir --upgrade pip setuptools wheel \
    && /opt/ansible/bin/pip install --no-cache-dir \
        ansible-core==2.14.12 \
        ansible-lint==6.22.0 \
        pyyaml==6.0.1

# Add a deterministic, non-root user without a default password or sudo access.
RUN groupadd --gid "${USER_GID}" "${USER_NAME}" \
    && useradd --create-home --shell /bin/bash --uid "${USER_UID}" --gid "${USER_GID}" "${USER_NAME}"

WORKDIR /workspace/project

# Copy project files with non-root ownership. In local development this is
# typically overridden by a bind mount.
COPY --chown=${USER_UID}:${USER_GID} . /workspace/project

USER ${USER_UID}:${USER_GID}

CMD ["/bin/bash"]
