# MicroCloud Edge Platform - Operations Guide

This guide covers day-to-day operations, maintenance, and management of a MicroCloud edge cloud platform.

## Table of Contents

1. [Monitoring](#monitoring)
2. [Instance Management](#instance-management)
3. [Cluster Management](#cluster-management)
4. [Backup and Recovery](#backup-and-recovery)
5. [Maintenance](#maintenance)
6. [Scaling](#scaling)
7. [Security Operations](#security-operations)

---

## Monitoring

### Cluster Health

```bash
# Quick status check
microcloud status

# Detailed cluster info
lxc cluster list

# Node information
lxc cluster info <node-name>
```

### Resource Monitoring

```bash
# Check cluster resource usage
lxc info

# Check specific instance
lxc info <instance-name>

# Real-time metrics
lxc monitor --pretty
```

### System Resources

```bash
# CPU, Memory, Disk
lxc list

# Check storage pools
lxc storage info <pool-name>

# Check network stats
lxc network info <network-name>
```

### Logging

```bash
# LXD logs
journalctl -u snap.lxd.daemon -f

# MicroCloud logs
microcloud logs

# Instance logs
lxc console <instance-name> --show-log
```

---

## Instance Management

### Creating Instances

```bash
# Basic container
lxc launch ubuntu:22.04 my-container

# Basic VM
lxc launch ubuntu:22.04 my-vm --vm

# With custom configuration
lxc launch ubuntu:22.04 web-server \
  -c security.nesting=true \
  -c limits.cpu=2 \
  -c limits.memory=2GiB

# From specific image
lxc launch ubuntu:22.04:amd64 my-app --alias myapp
```

### Instance Configuration

```bash
# View configuration
lxc config show <instance-name>

# Edit configuration
lxc config edit <instance-name>

# Set resource limits
lxc config set <instance-name> limits.cpu=4
lxc config set <instance-name> limits.memory=8GiB

# Enable nesting (for Docker)
lxc config set <instance-name> security.nesting=true
```

### Instance Operations

```bash
# Start instance
lxc start <instance-name>

# Stop instance
lxc stop <instance-name>

# Restart instance
lxc restart <instance-name>

# Delete instance
lxc delete <instance-name> --force

# Access instance shell
lxc exec <instance-name> -- bash
```

### Instance Networking

```bash
# Get instance IP
lxc list | grep <instance-name>

# Assign static IP
lxc config device set <instance-name> eth0 ipv4.address=10.168.1.50

# Add port forward
lxc config device add <instance-name> nginx proxy listen=tcp:0.0.0.0:80 connect=tcp:127.0.0.1:80
```

### Instance Storage

```bash
# Add additional disk
lxc config device add <instance-name> data disk pool=ceph-pool path=/data

# Resize storage
lxc config device set <instance-name> data size=10GiB
```

---

## Cluster Management

### Adding Nodes

```bash
# On initiator node
microcloud add-node

# On new node
sudo microcloud init
```

### Removing Nodes

```bash
# Remove node from cluster
lxc cluster remove <node-name>

# Evict node
lxc cluster evict <node-name>
```

### Node Maintenance

```bash
# Drain node (prevent new instances)
lxc cluster set <node-name> state=drain

# Disable node
lxc cluster set <node-name> state=offline

# Enable node
lxc cluster set <node-name> state=online
```

### Storage Management

```bash
# Add OSD to Ceph
microceph disk add /dev/sdb

# Remove OSD
microceph disk remove /dev/sdb

# Check Ceph status
microceph status
```

### Network Management

```bash
# Check OVN status
microovn status

# Add chassis
microovn chassis-add

# List networks
lxc network list
```

---

## Backup and Recovery

### Instance Snapshots

```bash
# Create snapshot
lxc snapshot <instance-name> <snapshot-name>

# Restore from snapshot
lxc restore <instance-name> <snapshot-name>

# Delete snapshot
lxc delete <instance-name>/<snapshot-name>

# List snapshots
lxc snapshot list <instance-name>
```

### Instance Backups (Export/Import)

```bash
# Export instance
lxc export <instance-name> /backup/<instance-name>.tar.gz

# Import instance
lxc import /backup/<instance-name>.tar.gz

# Delete original after import
lxc delete <instance-name>
```

### Automated Backups

Schedule regular backups using cron:

```bash
# Create backup script
cat > /usr/local/bin/lxd-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d)

for instance in $(lxc list -c n --format csv); do
    lxc export "$instance" "$BACKUP_DIR/${instance}-$DATE.tar.gz"
done

# Keep only 7 days of backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
EOF

chmod +x /usr/local/bin/lxd-backup.sh

# Add to crontab
crontab -e
# Add: 0 2 * * * /usr/local/bin/lxd-backup.sh
```

### Recovery Procedures

```bash
# From snapshot
lxc restore <instance-name> <snapshot-name>

# From backup
lxc delete <instance-name>
lxc import /backup/<instance-name>.tar.gz
lxc start <instance-name>
```

---

## Maintenance

### System Updates

```bash
# Update snaps
sudo snap refresh

# Update specific snap
sudo snap refresh lxd

# Update all MicroCloud components
sudo snap refresh microcloud lxd microceph microovn
```

### Log Rotation

```bash
# Configure log rotation
cat > /etc/logrotate.d/lxd {
    /var/log/lxd/*.log {
        daily
        rotate 7
        compress
        delaycompress
        missingok
        notifempty
    }
}
```

### Cleanup

```bash
# Remove stopped instances
lxc delete $(lxc list --format csv -c n | grep STOPPED) --force

# Clean up unused images
lxc image list
lxc image delete <image-alias>

# Clean up orphaned volumes
lxc storage volume list <pool-name>
```

### Performance Tuning

```bash
# Compression for network efficiency
lxc config set core.compression_algorithm=zstd

# CPU limits
lxc config set <instance> limits.cpu=4

# Memory limits  
lxc config set <instance> limits.memory=4GiB

# IO limits
lxc config set <instance> limits.disk.throttle.read=50MB
lxc config set <instance> limits.disk.throttle.write=50MB
```

---

## Scaling

### Horizontal Scaling

Add more cluster nodes:

```bash
# On new server
sudo snap install microcloud lxd microceph microovn

# On initiator
microcloud add-node
```

### Vertical Scaling

Resize instance:

```bash
# Resize resources
lxc config set <instance> limits.memory=8GiB
lxc config set <instance> limits.cpu=4

# Restart to apply
lxc restart <instance>
```

### Storage Scaling

Add storage to cluster:

```bash
# Add disk to Ceph
microceph disk add /dev/sdX
```

---

## Security Operations

### User Management

```bash
# Add user
lxc config get core.trust_password

# Set password
lxc config set core.trust_password <password>

# Remote access
lxc remote add cluster-2 https://<ip>:8443
```

### Access Control

```bash
# Create network ACL
lxc network acl create <acl-name>

# Create network rule
lxc network rule <acl-name> create \
  source=10.0.0.0/24 \
  action=allow
```

### Encryption

```bash
# Enable storage encryption
lxc storage create encrypted-pool ceph \
  volume.size=10GiB \
  ceph.rbd.encrypted=true
```

### Firewall

```bash
# UFW rules
sudo ufw allow 8443/tcp
sudo ufw allow 8444/tcp
sudo ufw allow 3300/tcp
sudo ufw allow 6642/tcp

# Enable firewall
sudo ufw enable
```

---

## Troubleshooting

See [Troubleshooting Guide](troubleshooting.md) for common issues and solutions.

---

## Quick Reference

### Common Commands

| Task | Command |
|------|---------|
| List instances | `lxc list` |
| Start all | `lxc start --all` |
| Stop all | `lxc stop --all` |
| Cluster status | `microcloud status` |
| Health check | `./scripts/health-check.sh` |

### Emergency Contacts

- **MicroCloud**: [GitHub Issues](https://github.com/canonical/microcloud/issues)
- **LXD**: [Discourse](https://discuss.linuxcontainers.org/c/lxd/41)