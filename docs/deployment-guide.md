# MicroCloud Edge Platform - Deployment Guide

This guide provides step-by-step instructions for deploying a MicroCloud edge cloud platform.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Single Node Deployment](#single-node-deployment)
3. [Multi-Node Cluster Deployment](#multi-node-cluster-deployment)
4. [Network Configuration](#network-configuration)
5. [Storage Configuration](#storage-configuration)
6. [Verifying Deployment](#verifying-deployment)
7. [First Steps](#first-steps)

---

## Prerequisites

### Hardware Requirements

| Deployment Type | Nodes | CPU | RAM | Storage | Network |
|----------------|-------|-----|-----|---------|---------|
| Development | 1 | 2 cores | 4 GB | 40 GB | 1 Gbps |
| Production | 3 | 4 cores | 8 GB | 80 GB | 10 Gbps |
| Enterprise | 5+ | 8 cores | 16 GB | 160 GB | 10+ Gbps |

### Software Requirements

- Ubuntu 22.04 LTS or newer (Ubuntu Server recommended)
- Root or sudo access
- Stable network connectivity between all nodes
- At least one additional disk for Ceph storage (production)

### Network Requirements

- All nodes must be on the same Layer 2 network (for mDNS discovery)
- Or use `--bootstrap-lookup` with external DNS
- Firewall ports to open:
  - `8443/tcp` - MicroCloud API
  - `8444/tcp` - LXD API  
  - `3300/tcp` - MicroCeph
  - `6642/tcp` - MicroOVN
  - `53/udp` - DNS (mDNS)
  - `5353/udp` - mDNS

---

## Single Node Deployment

Best for: Development, testing, evaluation

### Step 1: Install Dependencies

```bash
cd scripts
sudo ./install-dependencies.sh
```

This installs:
- MicroCloud snap
- LXD snap
- MicroCeph snap
- MicroOVN snap

### Step 2: Initialize MicroCloud

```bash
sudo ./init-single-node.sh
```

This will:
1. Detect available disks for storage
2. Configure networking
3. Initialize MicroCloud in single-node mode

### Step 3: Verify Deployment

```bash
microcloud status
lxc cluster list
```

Expected output:
```
MicroCloud: 1/1 member
Cluster: 1 member
```

---

## Multi-Node Cluster Deployment

Best for: Production, high availability, edge deployments

### Network Topology

```
┌──────────────────────────────────────────────────────────┐
│                    Edge Network                          │
│                                                          │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐            │
│  │ Node 01 │   │ Node 02 │   │ Node 03 │            │
│  │ Init +  │◄──│ Worker  │◄──│ Worker  │            │
│  │ Storage │   │ Storage │   │ Storage │            │
│  └────────┘   └────────┘   └────────┘            │
│       │            │            │                     │
│       └────────────┴────────────┘                     │
│              Cluster Communication                        │
└──────────────────────────────────────────────────────────┘
```

### Step 1: Prepare All Nodes

On **each node**, run:

```bash
cd scripts
sudo ./install-dependencies.sh
```

### Step 2: Initialize the First Node

On **Node 01** (the initiator):

```bash
sudo ./init-cluster.sh 3
```

This will:
1. Initialize MicroCloud
2. Wait for other nodes to join
3. Create the initial cluster

### Step 3: Join Additional Nodes

On **Node 02** and **Node 03**:

```bash
sudo microcloud init
```

Follow the prompts to join the cluster.

### Step 4: Verify the Cluster

```bash
# On any cluster node
microcloud status
```

Expected output:
```
MicroCloud: 3/3 members
Cluster: 3 members
  - node01 (initiator, storage)
  - node02 (worker, storage)  
  - node03 (worker, storage)
```

---

## Network Configuration

### Automatic Configuration (Recommended)

MicroCloud automatically configures networking using MicroOVN:

```bash
# Network is created automatically during init
lxc network list
```

### Custom Network Configuration

Create a custom OVN network:

```bash
# Create OVN network
lxc network create my-ovn \
  network_type=ovn \
  ipv4.address=10.168.1.1/24 \
  ipv4.dhcp=true \
  ipv4.nat=true
```

### VLAN Configuration

For segmented networks:

```bash
# Create VLAN network  
lxc network create edge-vlan \
  network_type=ovn \
  vlan.id=100 \
  ipv4.address=10.100.1.1/24
```

---

## Storage Configuration

### Automatic Storage (Default)

MicroCloud automatically creates a Ceph storage pool if disks are available.

### Check Storage

```bash
# List storage pools
lxc storage list

# View pool details
lxc storage info default
```

### Manual Storage Pool

Create additional storage:

```bash
# Local storage pool
lxc storage create local-pool dir \
  source=/var/lib/lxd/storage-pools/local

# Ceph storage pool
lxc storage create ceph-pool ceph \
  source=ceph
```

---

## Verifying Deployment

### Health Check

Run the health check script:

```bash
./scripts/health-check.sh
```

### Verify Components

```bash
# Check all components
microcloud status
lxc cluster list
microceph status
microovn status

# Test cluster communication
lxc list
lxc network list
lxc storage list
```

### Test Instance Creation

Create a test container:

```bash
lxc launch ubuntu:22.04 test-container
lxc list
```

Create a test VM:

```bash
lxc launch ubuntu:22.04 test-vm --vm
lxc list
```

---

## First Steps

### Access the Cluster

#### Local Access

```bash
lxc list
lxc exec my-container -- bash
```

#### Remote Access (Web UI)

Access the LXD web UI at:
- URL: `https://<node-ip>:8443`
- Username: `admin`
- Password: (set with `lxc config set core.trust_password`)

#### Remote Access (CLI)

```bash
# Add remote
lxc remote add my-cluster https://<node-ip>:8443

# List instances on remote
lxc list my-cluster:

# Access remote
lxc exec my-cluster:my-container -- bash
```

### Create Your First Workload

```bash
# Container
lxc launch ubuntu:22.04 web-server
lxc config set web-server security.nesting=true
lxc config set web-server rocker apt update && apt install -y nginx

# VM for heavier workloads
lxc launch ubuntu:22.04 database --vm
lxc config set database linux.kernel_modules=ext4
```

### Next Steps

1. **Configure backups**: Set up automated backups
2. **Configure monitoring**: Add Prometheus/Grafana
3. **Configure load balancing**: Set up load balancer
4. **Harden security**: Configure firewall, enable encryption
5. **Scale horizontally**: Add more nodes as needed

---

## Troubleshooting

See [Troubleshooting Guide](troubleshooting.md) for common issues and solutions.

## Security Notes

- Change default passwords immediately
- Use strong authentication
- Keep systems updated: `sudo snap refresh`
- Review firewall rules
- Enable logging and monitoring

---

## Additional Resources

- [MicroCloud Official Documentation](https://canonical.com/microcloud/docs)
- [LXD Documentation](https://documentation.ubuntu.com/lxd/)
- [MicroCeph Documentation](https://canonical.com/microceph/docs)
- [MicroOVN Documentation](https://canonical.com/microovn/docs)