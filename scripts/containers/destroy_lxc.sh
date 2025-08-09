#!/usr/bin/env bash
set -euo pipefail

# Stop and destroy a Proxmox LXC by VMID. Run on Proxmox node.

if [[ $# -lt 1 ]]; then
  echo "Usage: sudo ./scripts/containers/destroy_lxc.sh <VMID>" >&2
  exit 1
fi

VMID="$1"

command -v pct >/dev/null 2>&1 || { echo "Required: pct" >&2; exit 1; }

if pct status "$VMID" >/dev/null 2>&1; then
  echo "[info] Stopping LXC $VMID if running"
  pct stop "$VMID" || true
  echo "[info] Destroying LXC $VMID"
  pct destroy "$VMID" -force 1
else
  echo "[warn] LXC $VMID not found"
fi

echo "[done]"