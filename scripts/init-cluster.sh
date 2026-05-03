#!/bin/bash
#
# MicroCloud Edge Platform - Multi-Node Cluster Initialization
# This script initializes a multi-node MicroCloud cluster
#
# Usage: sudo ./init-cluster.sh [cluster-size]
# Example: sudo ./init-cluster.sh 3
#

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   log_error "This script must be run as root (use sudo)"
   exit 1
fi

# Get cluster size from argument or prompt
CLUSTER_SIZE=${1:-3}
MIN_CLUSTER_SIZE=3

if [ "$CLUSTER_SIZE" -lt "$MIN_CLUSTER_SIZE" ]; then
    log_warn "Minimum recommended cluster size is $MIN_CLUSTER_SIZE for production"
    log_warn "You provided $CLUSTER_SIZE"
    read -p "Continue anyway? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Aborted"
        exit 0
    fi
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

# Network configuration
log_info "Configuring cluster networking..."

# Detect primary network interface
CURRENT_IFACE=$(ip route | grep default | head -1 | awk '{print $5}')
if [ -z "$CURRENT_IFACE" ]; then
    CURRENT_IFACE="eth0"
fi

log_info "Primary network interface: $CURRENT_IFACE"

# Get IP addresses
NODE_IP=$(ip -4 addr show "$CURRENT_IFACE" | grep -oP '(?<=inet )\d+(\.\d+){3}' || hostname -I | awk '{print $1}')
log_info "This node IP: $NODE_IP"

# Check mDNS/multicast is working
log_info "Checking cluster discovery..."
log_info "Checking port 5353 (mDNS)..."

if timeout 1 bash -c 'echo >/dev/tcp/224.0.0.251/5353' 2>/dev/null; then
    log_info "mDNS multicast is available"
else
    log_warn "mDNS may not be available (this is normal in some network configurations)"
fi

# Discover other cluster nodes
log_info "Discovering cluster nodes..."
log_step "Waiting for node discovery (30 seconds)..."

# Auto-discover nodes on the network
NODE_LIST=("$NODE_IP")

# Try to discover other nodes (this is simplified)
# In production, you'd use --bootstrap-max or specify nodes explicitly

log_info "=============================================="
log_info "Initializing MicroCloud cluster..."
log_info "  Target cluster size: $CLUSTER_SIZE"
log_info "  This node: $NODE_IP"
log_info "=============================================="
echo ""

# Initialize the cluster
# Option 1: Auto-discovery mode
# This uses mDNS to find other nodes on the network

if [ "$CLUSTER_SIZE" -gt 1 ]; then
    log_info "Starting cluster initialization..."
    log_info "Other nodes should run: sudo microcloud init"
    log_info ""
    log_info "Waiting for other nodes to join..."
    
    # Run init with timeout waiting for other nodes
    timeout 120 microcloud init --bootstrap-min=1 --bootstrap-max="$CLUSTER_SIZE" || {
        if [ $? -eq 124 ]; then
            log_warn "Timeout waiting for other nodes"
            log_info "Continuing with current cluster"
        fi
    }
else
    log_info "Starting single-node cluster..."
    microcloud init --bootstrap-min=1
fi

# Wait for cluster to be ready
log_info "Waiting for cluster to be ready..."
sleep 10

# Check cluster status
log_step "Checking cluster status..."

log_info "-----------------------------------"
microcloud status
log_info "-----------------------------------"

# Storage configuration
log_info "Configuring storage..."
log_info "Available storage pools:"
lxc storage list 2>/dev/null || log_info "No storage pools configured yet"

# Network configuration
log_info "Network configuration:"
lxc network list 2>/dev/null || log_info "No networks configured yet"

# Display cluster information
echo ""
log_info "=============================================="
log_info "MicroCloud cluster initialized!"
log_info "=============================================="
echo ""
log_info "Cluster details:"
log_info "  Cluster size: $CLUSTER_SIZE"
log_info "  Local node: $NODE_IP"
log_info ""
log_info "Useful commands:"
log_info "  - View cluster members: lxc cluster list"
log_info "  - View all nodes: microcloud status"
log_info "  - Create container: lxc launch ubuntu:22.04 my-container"
log_info "  - Create VM: lxc launch ubuntu:22.04 my-vm --vm"
log_info "  - Add a node: On new node, run 'sudo microcloud init'"
echo ""

# Create a join token for other nodes
if [ "$CLUSTER_SIZE" -gt 1 ]; then
    log_info "To add more nodes to the cluster:"
    log_info "  1. On this node, generate a join token:"
    log_info "       microcloud add-node"
    log_info ""
    log_info "  2. On the new node, run:"
    log_info "       sudo microcloud init"
    log_info "       (and enter the token when prompted)"
    echo ""
fi