# MicroCloud Edge Platform - Troubleshooting Guide

This guide provides solutions to common issues encountered when deploying and operating a MicroCloud edge cloud platform.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Cluster Formation Issues](#cluster-formation-issues)
3. [Storage Issues](#storage-issues)
4. [Network Issues](#network-issues)
5. [Instance Issues](#instance-issues)
6. [Performance Issues](#performance-issues)
7. [Recovery Procedures](#recovery-procedures)

---

## Installation Issues

### Issue: Snap Installation Fails

**Symptoms:**
- `snap install` fails with network error
- Connection timeout errors

**Solutions:**
```bash
# Check network connectivity
curl -s https://api.snapcraft.io/ | head

# Check firewall
sudo ufw status

# Try with HTTP proxy
export HTTP_PROXY=http://proxy:port
export HTTPS_PROXY=http://proxy:port
snap install microcloud

# Use --unauthenticated flag (testing only)
snap install microcloud --unauthenticated
```

### Issue: Kernel Module Not Available

**Symptoms:**
- LXD fails to start
- Error: "modprobe: module not found"

**Solutions:**
```bash
# Enable required modules
sudo modprobe br_netfilter
sudo modprobe overlay

# Make modules persistent
echo br_netfilter | sudo tee /etc/modules-load.d/microcloud.conf
echo overlay | sudo tee -a /etc/modules-load.d/microcloud.conf

# Check kernel version
uname -r

# Update kernel if needed
sudo apt update && sudo apt upgrade
```

### Issue: Insufficient Disk Space

**Symptoms:**
- Installation fails with "no space left on device"
- Snap refresh fails

**Solutions:**
```bash
# Check disk space
df -h

# Clean up old packages
sudo apt autoremove

# Clean snap cache
sudo snap cache --help
sudo rm -rf /var/lib/snapd/cache/*

# Expand disk if using LVM
sudo lvextend -L +10G /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
```

---

## Cluster Formation Issues

### Issue: Nodes Not Discovering Each Other

**Symptoms:**
- `microcloud init` hangs waiting for other nodes
- Timeout after finding 0 cluster members

**Solutions:**
```bash
# Check mDNS availability
avahi-resolve -n microcloud.local 2>/dev/null

# Verify network connectivity
ping <node-ip>

# Check port 5353 (mDNS)
nc -zvu 224.0.0.251 5353

# Use explicit join instead of auto-discovery
# On initiator:
microcloud init --bootstrap-max=3

# On other nodes:
microcloud init --lookup=<initiator-ip>
```

### Issue: Cluster Join Fails

**Symptoms:**
- Error: "Failed to join cluster"
- Authentication or trust error

**Solutions:**
```bash
# Ensure network connectivity
ping <initiator-node-ip>

# Check ports are open
nc -zv <initiator-ip> 8443
nc -zv <initiator-ip> 8444

# Remove and rejoin
# On failed node:
sudo microcloud init --force

# Try with --accept-certificates flag
microcloud init --accept-certificates

# Check system clock
timedatectl
sudo systemctl restart systemd-timesyncd
```

### Issue: "Too Few Cluster Members"

**Symptoms:**
- Initialization fails with "minimum cluster size not met"
- Need at least 3 nodes for production

**Solutions:**
```bash
# For development/testing, use single node mode
microcloud init --skip-cluster

# Or accept lower minimum
microcloud init --bootstrap-min=1

# For production, add more nodes
# Then try again
```

---

## Storage Issues

### Issue: Ceph OSD Not Starting

**Symptoms:**
- `microceph status` shows OSD down
- Storage pool unavailable

**Solutions:**
```bash
# Check disk is available
lsblk /dev/sdb

# Add disk to Ceph
microceph disk add /dev/sdb --wipe

# Check OSD status
microceph osd list

# Start OSD
microceph osd start /dev/sdb1
```

### Issue: Storage Pool Creation Fails

**Symptoms:**
- `lxc storage create` fails
- Error: "Pool type not supported"

**Solutions:**
```bash
# Check Ceph status
microceph status

# Try with different driver
lxc storage create local-pool dir source=/path

# Check available drivers
lxc info
```

### Issue: No Storage Space

**Symptoms:**
- Instance creation fails: "no space left"
- Write operations fail

**Solutions:**
```bash
# Check pool usage
lxc storage info <pool-name>

# Add capacity
microceph disk add /dev/sdc

# Resize existing volume
# For LVM-thin:
lvextend -L +100G /dev/vg1/lxd_pool
lvresize -l +100%FREE /dev/vg1/lxd_pool
```

---

## Network Issues

### Issue: OVN Not Initialized

**Symptoms:**
- Network creation fails
- Error: "OVN not available"

**Solutions:**
```bash
# Check MicroOVN status
microovn status

# Initialize OVN
microovn init

# Restart services
sudo snap restart microovn
sudo snap restart lxd
```

### Issue: Instance No Network Access

**Symptoms:**
- Container has no IP
- Cannot reach internet from instance

**Solutions:**
```bash
# Check network configuration
lxc network list

# Check instance IP
lxc list
lxc info <instance>

# Restart instance
lxc stop <instance>
lxc start <instance>

# Check DHCP
lxc console <instance>

# Verify network on host
ip addr show br0
```

### Issue: Port Forward Not Working

**Symptoms:**
- Cannot reach service from external
- Connection refused

**Solutions:**
```bash
# Check proxy device
lxc config device show <instance>

# Remove and recreate proxy
lxc config device remove <instance> proxy0
lxc config device add <instance> proxy0 \
  proxy listen=tcp:0.0.0.0:80 connect=tcp:127.0.0.1:80

# Check firewall
sudo ufw status
sudo iptables -L -n
```

---

## Instance Issues

### Issue: Instance Won't Start

**Symptoms:**
- `lxc start` fails
- Error: "Failed to start instance"

**Solutions:**
```bash
# Check instance status
lxc info <instance>

# View logs
lxc console <instance> --show-log

# Check resources
lxc cluster list
# Ensure enough CPU/Memory available

# Try with different profile
lxc start <instance> --force
```

### Issue: Instance Stuck in Stopping

**Symptoms:**
- Instance state shows "Stopping" indefinitely
- Cannot delete instance

**Solutions:**
```bash
# Force stop
lxc stop <instance> --force

# Or wait for timeout
# After 30s, try again with force

# If still stuck:
lxc delete <instance> --force
# May need cluster member restart
```

### Issue: Permission Denied

**Symptoms:**
- Cannot access instance
- Permission errors

**Solutions:**
```bash
# Check trust
lxc config get core.trust_password

# Add remote with password
lxc remote add cluster --password=<password>

# Use sudo for privileged operations
sudo lxc exec <instance> -- root
```

---

## Performance Issues

### Issue: Slow Instance Performance

**Symptoms:**
- High CPU usage
- Slow disk IO

**Solutions:**
```bash
# Check instance resource limits
lxc config show <instance>

# Adjust limits
lxc config set <instance> limits.cpu=4
lxc config set <instance> limits.memory=4GiB

# Use local storage instead of Ceph
lxc config set <instance> root.pool=local-pool

# Enable nesting for Docker
lxc config set <instance> security.nesting=true
```

### Issue: High Memory Usage

**Symptoms:**
- System running out of memory
- OOM killer activating

**Solutions:**
```bash
# Check memory usage
free -h
lxc list

# Reduce instance count or sizes
lxc config set <instance> limits.memory=1GiB

# Add more cluster nodes
```

---

## Recovery Procedures

### Complete Cluster Recovery

```bash
# Save state
lxc list > /backup/instances.txt
microcloud status > /backup/status.txt

# Stop all instances
lxc stop --all

# Stop cluster services
sudo snap stop microcloud
sudo snap stop lxd
sudo snap stop microovn
sudo snap stop microceph

# Backup data
sudo tar czf /backup/lxd-data.tar.gz /var/lib/lxd

# Restore or reinstall
# Follow deployment guide
```

### Single Node Recovery

```bash
# Evict node from cluster
lxc cluster evict <node-name>

# Reinstall and rejoin
sudo microcloud init
```

### Data Recovery from Backup

```bash
# List backups
ls -la /backup/

# Import instance
lxc import /backup/<instance-name>.tar.gz

# Restore from snapshot
lxc restore <instance-name> <snapshot-name>
```

---

## Emergency Contacts

| Issue | Resource |
|-------|----------|
| MicroCloud Bugs | [GitHub Issues](https://github.com/canonical/microcloud/issues) |
| LXD Support | [Discourse](https://discuss.linuxcontainers.org/c/lxd/41) |
| Documentation | [Ubuntu Docs](https://documentation.ubuntu.com/lxd/) |

---

## Diagnostic Commands

```bash
# Collect diagnostic information
microcloud status
lxc cluster list
lxc info
lxc storage list
lxc network list
lxc list --verbose

# System information
hostname -I
free -h
df -h
uptime
journalctl -xe

# Service status
systemctl status snap.lxd.daemon
journalctl -u snap.lxd.daemon -n 100
```