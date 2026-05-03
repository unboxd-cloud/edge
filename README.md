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
# Install MicroCloud and dependencies
sudo snap install microcloud lxd microceph microovn

# Initialize MicroCloud
sudo microcloud init
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

## Deployment Options

### Option 1: Manual Setup

Use the provided shell scripts for manual deployment:
```bash
cd scripts
chmod +x install-dependencies.sh
sudo ./install-dependencies.sh
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

## Resources

- [MicroCloud Official Documentation](https://canonical.com/microcloud/docs)
- [LXD Documentation](https://documentation.ubuntu.com/lxd/)
- [MicroCeph Documentation](https://canonical.com/microceph/docs)
- [MicroOVN Documentation](https://canonical.com/microovn/docs)
- [Canonical MicroCloud GitHub](https://github.com/canonical/microcloud)