#!/bin/bash
#
# MicroCloud Edge Platform - One-command single-node demo deployment
#
# Usage:
#   sudo ./scripts/deploy-single-node-demo.sh
#   sudo ./scripts/deploy-single-node-demo.sh --purge-lxd
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PURGE_LXD="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --purge-lxd)
            PURGE_LXD="true"
            shift
            ;;
        *)
            log_error "Unknown argument: $1"
            exit 1
            ;;
    esac
done

lxd_is_initialized() {
    local dump
    dump="$(lxd init --dump 2>/dev/null || true)"

    if [[ "$dump" == *"networks: []"* && "$dump" == *"storage_pools: []"* ]]; then
        return 1
    fi

    return 0
}

get_primary_iface() {
    ip -4 route get 1.1.1.1 2>/dev/null | awk '/dev/ {for (i=1; i<=NF; i++) if ($i == "dev") print $(i+1)}' | head -n1
}

get_primary_ipv4() {
    ip -4 route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i=1; i<=NF; i++) if ($i == "src") print $(i+1)}' | head -n1
}

if [[ "$PURGE_LXD" == "true" ]] && snap list lxd &>/dev/null; then
    log_warn "Purging existing LXD state before deployment..."
    snap remove --purge lxd
fi

log_info "Installing compatible MicroCloud snap set..."
"$SCRIPT_DIR/install-dependencies.sh"

if lxd_is_initialized; then
    log_error "LXD is already initialized."
    log_error "Re-run with --purge-lxd if you want a clean demo deployment."
    exit 1
fi

HOSTNAME_VALUE="$(hostname)"
PRIMARY_IFACE="$(get_primary_iface)"
PRIMARY_IPV4="$(get_primary_ipv4)"

if [[ -z "$PRIMARY_IFACE" || -z "$PRIMARY_IPV4" ]]; then
    log_error "Unable to determine the primary IPv4 interface for MicroCloud."
    exit 1
fi

log_info "Using host $HOSTNAME_VALUE"
log_info "Using interface $PRIMARY_IFACE with IPv4 $PRIMARY_IPV4"

PRESEED_FILE="$(mktemp)"
trap 'rm -f "$PRESEED_FILE"' EXIT

cat > "$PRESEED_FILE" <<EOF
initiator_address: $PRIMARY_IPV4
session_passphrase: edge-demo-passphrase
systems:
  - name: $HOSTNAME_VALUE
    address: $PRIMARY_IPV4
EOF

log_info "Running MicroCloud single-node preseed bootstrap..."
set +e
PRESEED_OUTPUT="$(microcloud preseed < "$PRESEED_FILE" 2>&1)"
PRESEED_EXIT=$?
set -e
echo "$PRESEED_OUTPUT"

STATUS_OK="false"
if microcloud status >/dev/null 2>&1 && lxc cluster list >/dev/null 2>&1; then
    STATUS_OK="true"
fi

if [[ $PRESEED_EXIT -ne 0 && "$STATUS_OK" != "true" ]]; then
    log_error "MicroCloud bootstrap did not complete successfully."
    exit $PRESEED_EXIT
fi

if [[ $PRESEED_EXIT -ne 0 ]]; then
    log_warn "Bootstrap returned a non-zero status, but MicroCloud is reachable."
    log_warn "This usually indicates a partial demo deployment on a constrained VPS."
fi

PUBLIC_URL="https://$PRIMARY_IPV4:8443"

echo ""
log_info "Current cluster status:"
microcloud status || true
echo ""
log_info "LXD cluster view:"
lxc cluster list || true
echo ""
log_info "Demo UI:"
log_info "  $PUBLIC_URL"
log_info "Generate a browser trust token with:"
log_info "  lxc config trust add --name browser-ui"
