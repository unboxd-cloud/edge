#!/bin/bash
#
# MicroCloud Edge Platform - Dependencies Installation Script
# This script installs all required dependencies for MicroCloud deployment
#
# Usage: sudo ./install-dependencies.sh
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

# Check Ubuntu version
log_info "Checking Ubuntu version..."
OS=$(lsb_release -is 2>/dev/null || echo "Ubuntu")
VERSION=$(lsb_release -rs 2>/dev/null | cut -d. -f1)

if [[ "$OS" != "Ubuntu" ]]; then
    log_error "This script requires Ubuntu. Detected: $OS"
    exit 1
fi

if [[ "$VERSION" -lt 22 ]]; then
    log_error "This script requires Ubuntu 22.04 or newer. Detected: $VERSION"
    exit 1
fi

log_info "Ubuntu $VERSION detected - OK"

# Check if snap is installed
if ! command -v snap &> /dev/null; then
    log_error "Snap is not installed. Install snapd first:"
    log_error "  sudo apt update && sudo apt install -y snapd"
    exit 1
fi

log_info "Snap is installed - OK"

# Update snapd
log_info "Updating snapd..."
snap refresh core 2>/dev/null || true

# Install required snaps
log_info "Installing MicroCloud and related snaps..."

SNAPS=(
    "microcloud"
    "lxd"
    "microceph"
    "microovn"
)

install_or_refresh_snap() {
    local snap_name="$1"
    local snap_channel="$2"

    if snap list "$snap_name" &>/dev/null; then
        log_info "Refreshing $snap_name on $snap_channel..."
        snap refresh "$snap_name" --channel="$snap_channel" --cohort="+"
    else
        log_info "Installing $snap_name from $snap_channel..."
        snap install "$snap_name" --channel="$snap_channel" --cohort="+"
    fi
}

install_or_refresh_snap "lxd" "5.21/stable"
install_or_refresh_snap "microceph" "squid/stable"
install_or_refresh_snap "microovn" "24.03/stable"
install_or_refresh_snap "microcloud" "2/stable"

log_info "Holding snap refreshes for cluster consistency..."
snap refresh lxd microceph microovn microcloud --hold

# Enable required kernel modules
log_info "Enabling required kernel modules..."

KERNEL_MODULES=(
    "br_netfilter"
    "ip_tables"
    "ip6_tables"
    "netlink_diag"
    "nf_nat"
    "overlay"
)

for module in "${KERNEL_MODULES[@]}"; do
    if modprobe "$module" 2>/dev/null; then
        log_info "Loaded kernel module: $module"
    else
        log_warn "Could not load kernel module: $module"
    fi
done

# Configure system parameters
log_info "Configuring system parameters..."

# Disable AppArmor if not needed (for nested containers)
# This is optional and can be skipped
# log_warn "AppArmor is enabled by default"

# Configure networking for cluster communication
log_info "Configuring network settings..."

if [ -f /etc/sysctl.d/99-microcloud.conf ]; then
    log_warn "Network config already exists"
else
    cat > /etc/sysctl.d/99-microcloud.conf << EOF
# MicroCloud network configuration
net.ipv4.ip_forward=1
net.ipv4.conf.all.forwarding=1
net.bridge.bridge-nf-call-iptables=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.rp_filter=1
EOF
    log_info "Created network configuration in /etc/sysctl.d/99-microcloud.conf"
fi

# Apply network settings
sysctl -p /etc/sysctl.d/99-microcloud.conf

# Check firewall
log_info "Checking firewall status..."
if systemctl is-active --quiet ufw 2>/dev/null; then
    log_warn "UFW is active. You may need to allow cluster traffic:"
    log_warn "  sudo ufw allow 8443/tcp  # MicroCloud API"
    log_warn "  sudo ufw allow 8444/tcp  # LXD API"
    log_warn "  sudo ufw allow 3300/tcp # MicroCeph"
    log_warn "  sudo ufw allow 6642/tcp # MicroOVN"
fi

# Configure LXD bridging
log_info "Checking LXD bridging..."
if ! brctl show br0 &>/dev/null && [ ! -L /sys/class/net/br0 ]; then
    log_info "No bridge br0 detected - LXD will create one during init"
fi

# Verify installations
log_info "Verifying installations..."

for snap in "${SNAPS[@]}"; do
    if snap list "$snap" &>/dev/null; then
        VERSION=$(snap list "$snap" | grep "$snap" | awk '{print $3}')
        log_info "$snap installed: $VERSION"
    else
        log_error "$snap not installed"
        exit 1
    fi
done

# Summary
echo ""
log_info "=============================================="
log_info "Dependencies installation complete!"
log_info "=============================================="
echo ""
log_info "Next steps:"
log_info "  1. One-command single-node demo: sudo ./scripts/deploy-single-node-demo.sh"
log_info "  2. Or join cluster: sudo microcloud init --bootstrap-max=3"
log_info ""
log_info "For multi-node deployment, run this script on all nodes."
echo ""
