# Edge Cloud Platform - MicroCloud

A production-ready edge cloud platform built on Canonical's MicroCloud - a lightweight, open source cloud infrastructure solution optimized for edge computing, branch offices, and distributed environments.

## Overview

This project provides a complete infrastructure-as-code solution for deploying and managing a MicroCloud-based edge cloud platform. It includes automated setup scripts, Ansible playbooks for enterprise-scale deployment, and comprehensive configuration templates.

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   Edge Cloud Platform                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐      │
│  │   Node 1    │   │   Node 2    │   │   Node 3    │      │
│  │  (Control)  │   │  (Worker)   │   │  (Worker)  │      │
│  └──────┬──────┘   └──────┬──────┘   └──────┬──────┘      │
│         │                  │                  │              │
│  ┌──────┴──────────────────┴──────────────────┴──────┐   │
│  │                   MicroCloud Cluster                  │   │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │   │
│  │  │    LXD     │  │  MicroCeph  │  │  MicroOVN  │   │   │
│  │  │ (Compute)  │  │ (Storage)  │  │ (Network) │   │   │
│  │  └─────────────┘  └─────────────┘  └─────────────┘   │   │
│  └───────────────────────────────────────────────────────┘   │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Components

| Component | Description | Role |
|-----------|-------------|------|
| **LXD** | Container and VM hypervisor | Compute virtualization |
| **MicroCeph** | Distributed storage | Persistent block storage |
| **MicroOVN** | Open Virtual Network | Software-defined networking |
| **MicroCloud** | Cluster orchestration | Automation and management |

## Requirements

### Minimum Hardware

| Deployment Type | Nodes | CPU | RAM | Storage |
|-----------------|-------|-----|-----|---------|
| Single-node (dev) | 1 | 2 cores | 4 GB | 40 GB |
| Multi-node (prod) | 3 | 4 cores | 8 GB | 80 GB |

### Software Requirements

- Ubuntu 22.04 LTS or newer
- Snap package manager
- Root or sudo access
- Network connectivity between nodes

## Quick Start

### Single Node (Development)

```bash
# One-command demo deployment
sudo ./scripts/deploy-single-node-demo.sh

# If the machine already has initialized LXD state
sudo ./scripts/deploy-single-node-demo.sh --purge-lxd
```

### Multi-Node Cluster

On the first node (initiator):
```bash
sudo snap install microcloud lxd microceph microovn
sudo microcloud init
```

On additional nodes:
```bash
sudo snap install microcloud lxd microceph microovn
sudo microcloud init --bootstrap-max=3
```

## Project Structure

```
.
├── ansible/                    # Ansible playbooks for automation
│   ├── playbooks/
│   │   ├── setup-microcloud.yml
│   │   └── configure-cluster.yml
│   └── inventory/
├── docs/                        # Documentation
│   ├── deployment-guide.md
│   ├── operations-guide.md
│   └── troubleshooting.md
├── scripts/                     # Setup scripts
│   ├── install-dependencies.sh
│   ├── init-single-node.sh
│   └── init-cluster.sh
├── examples/                    # Configuration examples
│   ├── cloud-init.yaml
│   └── storage-config.yaml
├── terraform/                  # Infrastructure definitions
└── SPEC.md                     # Project specification
```

## Docker Usage

You can run this repository in a containerized development environment.

### Build the image

```bash
docker build -t edge-cloud-platform:local .
```

### Start dev shell

```bash
docker run --rm -it \
  -v "$PWD:/workspace/project" \
  --name edge-cloud-dev \
  edge-cloud-platform:local
```

### Use Docker Compose profiles

```bash
# Start dev environment
docker compose --profile dev up -d

# Start docs server at http://localhost:8080
docker compose --profile docs up -d

# Validate compose setup
docker compose config
```

> Note: running Snap-based MicroCloud components inside Docker is limited. Use containers for tooling, docs, and automation workflows.

### Production hardening status

This repository includes a **development-oriented** Docker setup and is **not a production runtime image** for MicroCloud services.

Current hardening measures:
- deterministic non-root user (`10001:10001`) without sudo access or a default password
- minimized package install (`--no-install-recommends`) and cleaned apt cache
- Ansible tooling installed in an isolated Python virtual environment under `/opt/ansible`
- Compose services run with `no-new-privileges`, dropped Linux capabilities, and an init process
- hardened docs container uses an unprivileged NGINX image, read-only filesystem, `tmpfs` writable paths, and a healthcheck
- expanded `.dockerignore` coverage for secrets, local state, language caches, and Terraform state

Before production use, additionally consider:
- pinning image digests and enabling base image update automation
- signed image provenance (for example, Sigstore/cosign)
- container vulnerability scanning in CI (for example, Trivy/Grype)
- runtime policy enforcement (seccomp/AppArmor/SELinux and network policies)
- CI validation with `docker build`, `docker compose config`, and image scanning on every change

## Deployment Options

### Option 1: Manual Setup

Use the provided shell scripts for manual deployment:
```bash
sudo ./scripts/deploy-single-node-demo.sh
```

### Option 2: Ansible Automation

Use Ansible playbooks for enterprise-scale deployment:
```bash
cd ansible
ansible-playbook -i inventory/hosts playbooks/setup-microcloud.yml
```

### Option 3: Terraform (Infrastructure)

Provision infrastructure with Terraform:
```bash
cd terraform
terraform init
terraform apply
```

## Configuration

### Network Configuration

Configure the cluster network by editing `examples/network-config.yaml`:

```yaml
network:
  mode: "ovn"              # Use MicroOVN for networking
  bridge: "br0"           # Physical bridge interface
  ipv4:
    range: "10.0.0.0/24"   # Cluster network range
    gateway: "10.0.0.1"
```

### Storage Configuration

Configure storage pools in `examples/storage-config.yaml`:

```yaml
storage:
  pools:
    - name: "ceph-pool"
      driver: "ceph"
      volume_size: "10GiB"
```

## Operations

### Check Cluster Status

```bash
# View MicroCloud status
microcloud status

# View LXD cluster status
lxc cluster list

# View MicroCeph status
microceph status
```

### Add New Node

```bash
# On new node
sudo microcloud init

# On existing cluster node
microcloud add-node
```

### Create Workload

```bash
# Create a container
lxc launch ubuntu:22.04 my-container

# Create a VM
lxc launch ubuntu:22.04 my-vm --vm
```

## Documentation

- [Deployment Guide](docs/deployment-guide.md) - Complete deployment instructions
- [Operations Guide](docs/operations-guide.md) - Day-to-day operations
- [Troubleshooting Guide](docs/troubleshooting.md) - Common issues and solutions

## Security Considerations

1. **Network Isolation**: Use VLANs or firewall rules to isolate cluster network
2. **Access Control**: Limit SSH access and use key-based authentication
3. **Storage Encryption**: Enable Ceph encryption for sensitive data
4. **Updates**: Keep snaps updated with `sudo snap refresh`

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

This project is licensed under the Apache 2.0 License - see the LICENSE file for details.

## Deployment Info (edge.unboxd.cloud)

This section reflects the current single-node demo state deployed on `edge.unboxd.cloud` on May 5, 2026.

### Current Node

| Field | Value |
|-------|-------|
| Hostname | `edge` |
| Public URL | `https://edge.unboxd.cloud:8443` |
| Public IP | `31.97.206.43` |
| OS | `Ubuntu 25.10` |
| Architecture | `x86_64` |
| Topology | `single-node demo` |

### Installed Snaps

| Snap | Channel |
|------|---------|
| `microcloud` | `2/stable` |
| `lxd` | `5.21/stable` |
| `microceph` | `squid/stable` |
| `microovn` | `24.03/stable` |

### Live Access

```bash
# LXD / MicroCloud web UI
open https://edge.unboxd.cloud:8443

# Cluster status
microcloud status
lxc cluster list
```

### Current Limitations

- This is a best-effort demo deployment on `Ubuntu 25.10`, not a documented supported MicroCloud base.
- The node has no configured MicroCeph OSDs, so there is no usable distributed storage yet.
- Full MicroCloud bootstrap hit a FAN networking failure on this VPS during cluster-wide device setup.
- The UI endpoint is live, but this should not be treated as a production-ready MicroCloud deployment.

### Notes

- `microcloud status` reports the node `ONLINE`.
- `lxc cluster list` reports `https://31.97.206.43:8443` as the active cluster endpoint.
- Browser access uses LXD trust-based authentication rather than a separate app-specific login flow.

## Resources

- [MicroCloud Official Documentation](https://canonical.com/microcloud/docs)
- [LXD Documentation](https://documentation.ubuntu.com/lxd/)
- [MicroCeph Documentation](https://canonical.com/microceph/docs)
- [MicroOVN Documentation](https://canonical.com/microovn/docs)
- [Canonical MicroCloud GitHub](https://github.com/canonical/microcloud)
