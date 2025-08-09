#!/usr/bin/env bash
set -euo pipefail

# Run on Proxmox node as root. Creates an LXC that serves a local model repository via nginx.

# Defaults
VMID=${VMID:-203}
HOSTNAME=${HOSTNAME:-model-repo}
STORAGE=${STORAGE:-local-lvm}
BRIDGE=${BRIDGE:-vmbr0}
IPADDR=${IPADDR:-10.0.0.102}
CIDR=${CIDR:-24}
GATEWAY=${GATEWAY:-10.0.0.1}
CORES=${CORES:-2}
MEMORY_MB=${MEMORY_MB:-1024}
DISK_GB=${DISK_GB:-10}
PASSWORD=${PASSWORD:-modelrepo}
UNPRIVILEGED=${UNPRIVILEGED:-1}

MODEL_ROOT=${MODEL_ROOT:-/srv/models}
HTTP_PORT=${HTTP_PORT:-8080}

usage() {
  cat <<EOF
Usage: sudo VMID=203 HOSTNAME=model-repo IPADDR=10.0.0.102 ./scripts/containers/create_model_repo_lxc.sh

Environment variables:
  VMID, HOSTNAME, STORAGE, BRIDGE, IPADDR, CIDR, GATEWAY, CORES, MEMORY_MB, DISK_GB, PASSWORD, UNPRIVILEGED
  MODEL_ROOT  (default: /srv/models)
  HTTP_PORT   (default: 8080)
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

provision_model_repo() {
  echo "[info] Provisioning Model Repository inside LXC ${VMID}"
  pct exec "${VMID}" -- bash -ceu "
    set -euo pipefail
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

    install -d -m 0755 ${MODEL_ROOT}
    chown -R www-data:www-data ${MODEL_ROOT}

    cat >/etc/nginx/sites-available/model_repo <<CONF
server {
    listen ${HTTP_PORT} default_server;
    listen [::]:${HTTP_PORT} default_server;

    server_name _;
    root ${MODEL_ROOT};
    autoindex on;

    location / {
        try_files $uri $uri/ =404;
    }
}
CONF

    rm -f /etc/nginx/sites-enabled/default
    ln -sf /etc/nginx/sites-available/model_repo /etc/nginx/sites-enabled/model_repo

    systemctl enable --now nginx
  "
}

main() {
  ensure_template
  create_container
  start_container
  provision_model_repo
  echo "[done] Model Repo LXC ${VMID} created at http://${IPADDR}:${HTTP_PORT}"
}

main "$@"