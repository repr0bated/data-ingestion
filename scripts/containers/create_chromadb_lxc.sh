#!/usr/bin/env bash
set -euo pipefail

# Run on Proxmox node as root. Creates an LXC for ChromaDB API.

# Defaults
VMID=${VMID:-202}
HOSTNAME=${HOSTNAME:-chromadb}
STORAGE=${STORAGE:-local-lvm}
BRIDGE=${BRIDGE:-vmbr0}
IPADDR=${IPADDR:-10.0.0.101}
CIDR=${CIDR:-24}
GATEWAY=${GATEWAY:-10.0.0.1}
CORES=${CORES:-2}
MEMORY_MB=${MEMORY_MB:-2048}
DISK_GB=${DISK_GB:-10}
PASSWORD=${PASSWORD:-chromadb}
UNPRIVILEGED=${UNPRIVILEGED:-1}

CHROMA_DATA_DIR=${CHROMA_DATA_DIR:-/var/lib/chroma}
CHROMA_PORT=${CHROMA_PORT:-8000}

usage() {
  cat <<EOF
Usage: sudo VMID=202 HOSTNAME=chromadb IPADDR=10.0.0.101 ./scripts/containers/create_chromadb_lxc.sh

Environment variables:
  VMID, HOSTNAME, STORAGE, BRIDGE, IPADDR, CIDR, GATEWAY, CORES, MEMORY_MB, DISK_GB, PASSWORD, UNPRIVILEGED
  CHROMA_DATA_DIR   (default: /var/lib/chroma)
  CHROMA_PORT       (default: 8000)
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage; exit 0
fi

require_cmd() { command -v "$1" >/dev/null 2>&1 || { echo "Required: $1" >&2; exit 1; }; }
require_cmd pct
require_cmd pveam

TEMPLATE_STORE="local"
TEMPLATE_NAME="debian-12-standard_12.2-1_amd64.tar.zst"

ensure_template() {
  pveam update >/dev/null 2>&1 || true
  if ! pvesh get /nodes/$(hostname)/storage/${TEMPLATE_STORE}/content | grep -q "${TEMPLATE_NAME}"; then
    echo "[info] Downloading template to ${TEMPLATE_STORE}:vztmpl/${TEMPLATE_NAME}"
    pveam download "${TEMPLATE_STORE}" "${TEMPLATE_NAME}"
  fi
}

create_container() {
  echo "[info] Creating LXC VMID=${VMID} HOSTNAME=${HOSTNAME}"
  pct create "${VMID}" "${TEMPLATE_STORE}:vztmpl/${TEMPLATE_NAME}" \
    -hostname "${HOSTNAME}" \
    -password "${PASSWORD}" \
    -cores "${CORES}" \
    -memory "${MEMORY_MB}" \
    -swap 512 \
    -rootfs "${STORAGE}:${DISK_GB}" \
    -net0 "name=eth0,bridge=${BRIDGE},ip=${IPADDR}/${CIDR},gw=${GATEWAY}" \
    -unprivileged "${UNPRIVILEGED}"
}

start_container() {
  pct start "${VMID}" || true
  echo "[info] Waiting for network..."
  sleep 5
}

provision_chromadb() {
  echo "[info] Provisioning ChromaDB inside LXC ${VMID}"
  pct exec "${VMID}" -- bash -ceu "
    set -euo pipefail
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-venv python3-pip build-essential git

    install -d -m 0755 /opt/chroma
    python3 -m venv /opt/chroma/venv
    /opt/chroma/venv/bin/python -m pip install --upgrade pip wheel
    /opt/chroma/venv/bin/python -m pip install chromadb uvicorn fastapi

    install -d -m 0755 ${CHROMA_DATA_DIR}

    cat >/etc/systemd/system/chromadb.service <<'UNIT'
[Unit]
Description=ChromaDB Vector Database API
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/opt/chroma
ExecStart=/opt/chroma/venv/bin/chroma run --host 0.0.0.0 --port ${CHROMA_PORT} --path ${CHROMA_DATA_DIR}
Restart=always

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now chromadb
  "
}

main() {
  ensure_template
  create_container
  start_container
  provision_chromadb
  echo "[done] ChromaDB LXC ${VMID} created at ${IPADDR}:${CHROMA_PORT}"
}

main "$@"