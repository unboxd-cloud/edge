# Edge Cloud Platform - Docker Development Environment
#
# This Dockerfile provides a development environment for working with the edge cloud platform.
# It includes all necessary tools for MicroCloud development and testing.
#
# Build: docker build -t edge-cloud-platform .
# Run:   docker run -it edge-cloud-platform bash

FROM ubuntu:22.04

LABEL maintainer="Edge Cloud Platform"
LABEL description="Development environment for MicroCloud edge platform"

# Install base dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    vim \
    htop \
    net-tools \
    iputils-ping \
    ca-certificates \
    gnupg \
    jq \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install microcloud development tools
RUN apt-get update && apt-get install -y \
    snapd \
    && rm -rf /var/lib/apt/lists/*

# Configure snapd for development (using classic confinement)
# Note: Snap inside Docker may have limitations

# Install Python packages for Ansible
RUN pip3 install --no-cache-dir \
    ansible-core==2.14.12 \
    ansible-lint==6.22.0 \
    pyyaml==6.0.1

# Add non-root user for development
RUN useradd -m -s /bin/bash developer && \
    echo "developer:developer" | chpasswd && \
    usermod -aG sudo developer

# Set working directory
WORKDIR /workspace/project

# Copy project files (these will be mounted in production)
COPY . /workspace/project

# Switch to non-root user
USER developer

# Set default environment
ENV DEBIAN_FRONTEND=noninteractive
ENV EDITOR=vim

# Default command
CMD ["/bin/bash"]