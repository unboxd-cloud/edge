#!/bin/bash
#
# MicroCloud Edge Platform - Single Node Initialization
# This script initializes a single-node MicroCloud for development/testing
#
# Usage: sudo ./init-single-node.sh
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

# Verify snaps are installed
log_info "Verifying MicroCloud snaps are installed..."

SNAPS=("microcloud" "lxd" "microceph" "microovn")
for snap in "${SNAPS[@]}"; do
    if ! snap list "$snap" &>/dev/null; then
        log_error "$snap is not installed. Run install-dependencies.sh first."
        exit 1
    fi
    VERSION=$(snap list "$snap" | grep "$snap" | awk '{print $3}')
    log_info "$snap: $VERSION"
done

# Get available disks for MicroCeph
log_info "Checking available disks..."

# List block devices (exclude loop and ram devices)
AVAILABLE_DISKS=$(lsblk -ndo NAME,TYPE,SIZE | grep disk | awk '{print $1 ":" $2}')

if [ -z "$AVAILABLE_DISKS" ]; then
    log_warn "No additional disks detected for Ceph storage"
    log_warn "MicroCloud will work with limited storage capacity"
    USE_CEPH="false"
else
    log_info "Available disks:"
    echo "$AVAILABLE_DISKS" | while read -r disk; do
        log_info "  - /dev/$disk"
    done
    
    # Let user select a disk for Ceph
    echo ""
    log_info "Select a disk for MicroCeph storage (or press Enter to skip):"
    read -r CEPH_DISK
    
    if [ -z "$CEPH_DISK" ]; then
        USE_CEPH="false"
    else
        if [ -b "/dev/$CEPH_DISK" ]; then
            USE_CEPH="true"
            CEPH_DISK_PATH="/dev/$CEPH_DISK"
        else
            log_error "Disk /dev/$CEPH_DISK not found"
            exit 1
        fi
    fi
fi

# Configure network
log_info "Configuring networking..."
log_info "Using MicroOVN for software-defined networking"

# Get current network interface
CURRENT_IFACE=$(ip route | grep default | head -1 | awk '{print $5}')
if [ -z "$CURRENT_IFACE" ]; then
    CURRENT_IFACE="eth0"
fi

log_info "Primary network interface: $CURRENT_IFACE"

# Initialize MicroCloud
log_info "=============================================="
log_info "Initializing MicroCloud in single-node mode..."
log_info "=============================================="
echo ""

# Run microcloud init in non-interactive mode where possible
# For single node, we use the --skip option for now
log_info "Starting MicroCloud initialization..."

# Create answer file for automated responses
cat > /tmp/microcloud-answers.txt << EOF
# MicroCloud initialization answers
# Format: key=value

# Cluster setup
microcloud_cluster_mode=standalone
microcloud_cluster_size=1

# Networking
microcloud_networking_mode=ovn
microcloud_bridge=$CURRENT_IFACE

# Storage
microcloud_storage_backend=ceph
EOF

if [ "$USE_CEPH" = "true" ]; then
    echo "microcloud_ceph_disk=$CEPH_DISK_PATH" >> /tmp/microcloud-answers.txt
fi

# Interactive initialization
# Note: This requires user interaction
microcloud init --bootstrap-min=1

# Wait for initialization to complete
log_info "Waiting for MicroCloud to be ready..."

# Check status
sleep 5
microcloud status

# Configure LXD for remote access (optional)
log_info "Setting up LXD remote access..."

# GenerateLXD password if needed
lxc config set core.trust_password="" || true

# Print access information
echo ""
log_info "=============================================="
log_info "MicroCloud initialized successfully!"
log_info "=============================================="
echo ""
log_info "Access the cluster:"
echo ""
log_info "  Local:    lxc list"
log_info "  Remote:  https://localhost:8443"
echo ""
log_info "  Username: admin"
log_info "  Password: (set with 'lxc config set core.trust_password')"
echo ""

log_info "Next steps:"
log_info "  1. Create your first container:"
log_info "       lxc launch ubuntu:22.04 my-first-container"
log_info ""
log_info "  2. Create a VM:"
log_info "       lxc launch ubuntu:22.04 my-vm --vm"
log_info ""
log_info "  3. Check status:"
log_info "       microcloud status"
log_info "       lxc cluster list"
echo ""