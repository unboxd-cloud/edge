#!/bin/bash
#
# MicroCloud Edge Platform - Health Check and Operations Script
# Check the health status of the MicroCloud cluster
#
# Usage: ./health-check.sh
#

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[CHECK]${NC} $1"; }

echo "=========================================="
echo "  MicroCloud Edge Platform - Health Check"
echo "=========================================="
echo ""

# Check MicroCloud status
log_step "MicroCloud Status"
if command -v microcloud &> /dev/null; then
    microcloud status 2>/dev/null && log_info "MicroCloud: OK" || log_error "MicroCloud: FAILED"
else
    log_error "MicroCloud: NOT INSTALLED"
fi
echo ""

# Check LXD status
log_step "LXD Status"
if command -v lxc &> /dev/null; then
    # LXD daemon status
    if systemctl is-active --quiet snap.lxd.daemon 2>/dev/null; then
        log_info "LXD Daemon: RUNNING"
    else
        log_warn "LXD Daemon: NOT RUNNING"
    fi
    
    # LXD cluster
    echo ""
    log_step "LXD Cluster Members:"
    lxc cluster list 2>/dev/null || log_warn "No cluster configured"
else
    log_error "LXD: NOT INSTALLED"
fi
echo ""

# Check MicroCeph status
log_step "MicroCeph Status"
if command -v microceph &> /dev/null; then
    microceph status 2>/dev/null && log_info "MicroCeph: OK" || log_warn "MicroCeph: NOT CONFIGURED"
else
    log_error "MicroCeph: NOT INSTALLED"
fi
echo ""

# Check MicroOVN status
log_step "MicroOVN Status"
if command -v microovn &> /dev/null; then
    microovn status 2>/dev/null && log_info "MicroOVN: OK" || log_warn "MicroOVN: NOT CONFIGURED"
else
    log_error "MicroOVN: NOT INSTALLED"
fi
echo ""

# Storage pools
log_step "Storage Pools"
lxc storage list 2>/dev/null || log_info "No storage pools"
echo ""

# Networks
log_step "Networks"
lxc network list 2>/dev/null || log_info "No networks"
echo ""

# Instances
log_step "Instances (Containers & VMs)"
lxc list 2>/dev/null || log_info "No instances"
echo ""

# System resources
log_step "System Resources"
echo "  CPU: $(nproc) cores"
echo "  Memory: $(free -h | awk '/^Mem:/{print $2}')"
echo "  Disk: $(df -h / | awk 'NR==2{print $3 "/" $2 " (" $5 " used)"}')"
echo ""

echo "=========================================="
echo "  Health Check Complete"
echo "=========================================="