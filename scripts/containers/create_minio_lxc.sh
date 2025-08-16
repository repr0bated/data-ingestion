#!/usr/bin/env bash
set -euo pipefail

# This script must be run on a Proxmox node with root privileges.
# It creates an LXC for MinIO and provisions MinIO as a systemd service.

# Defaults (override via env or flags)
VMID=${VMID:-201}
HOSTNAME=${HOSTNAME:-minio}
STORAGE=${STORAGE:-local-lvm}
BRIDGE=${BRIDGE:-vmbr0}
IPADDR=${IPADDR:-10.0.0.100}
CIDR=${CIDR:-24}
GATEWAY=${GATEWAY:-10.0.0.1}
CORES=${CORES:-2}
MEMORY_MB=${MEMORY_MB:-2048}
DISK_GB=${DISK_GB:-10}
PASSWORD=${PASSWORD:-minio}
UNPRIVILEGED=${UNPRIVILEGED:-1}

MINIO_ROOT_USER=${MINIO_ROOT_USER:-minioadmin}
MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD:-minioadmin}
MINIO_DATA_DIR=${MINIO_DATA_DIR:-/data/minio}

usage() {
  cat <<EOF
Usage: sudo VMID=201 HOSTNAME=minio IPADDR=10.0.0.100 ./scripts/containers/create_minio_lxc.sh

Environment variables:
  VMID            LXC ID (default: 201)
  HOSTNAME        Container hostname (default: minio)
  STORAGE         Proxmox storage for rootfs (default: local-lvm)
  BRIDGE          Proxmox network bridge (default: vmbr0)
  IPADDR          Static IP (default: 10.0.0.100)
  CIDR            CIDR bits (default: 24)
  GATEWAY         Gateway IP (default: 10.0.0.1)
  CORES           CPU cores (default: 2)
  MEMORY_MB       RAM MB (default: 2048)
  DISK_GB         Root disk size in GB (default: 10)
  PASSWORD        Root password for the LXC (default: minio)
  UNPRIVILEGED    1 for unprivileged, 0 for privileged (default: 1)

  MINIO_ROOT_USER      (default: minioadmin)
  MINIO_ROOT_PASSWORD  (default: minioadmin)
  MINIO_DATA_DIR       (default: /data/minio)
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
  if ! pveam available | grep -q "${TEMPLATE_NAME}"; then
    echo "[info] Downloading ${TEMPLATE_NAME} index"
  fi
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

provision_minio() {
  echo "[info] Provisioning MinIO inside LXC ${VMID}"
  pct exec "${VMID}" -- bash -ceu "
    set -euo pipefail
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y curl ca-certificates wget

    install -d -m 0755 /usr/local/bin
    curl -fsSL https://dl.min.io/server/minio/release/linux-amd64/minio -o /usr/local/bin/minio
    chmod +x /usr/local/bin/minio

    install -d -m 0755 ${MINIO_DATA_DIR}

    cat >/etc/systemd/system/minio.service <<'UNIT'
[Unit]
Description=MinIO Object Storage
After=network-online.target
Wants=network-online.target

[Service]
Environment="MINIO_ROOT_USER=${MINIO_ROOT_USER}"
Environment="MINIO_ROOT_PASSWORD=${MINIO_ROOT_PASSWORD}"
ExecStart=/usr/local/bin/minio server ${MINIO_DATA_DIR} --address :9000 --console-address :9001
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
UNIT

    systemctl daemon-reload
    systemctl enable --now minio
  "
}

main() {
  ensure_template
  create_container
  start_container
  provision_minio
  echo "[done] MinIO LXC ${VMID} created at ${IPADDR}. Ports: 9000 (S3), 9001 (console)"
}

main "$@"