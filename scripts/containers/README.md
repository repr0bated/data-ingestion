### Proxmox LXC Container Scripts

These scripts create Debian 12 LXC containers on a Proxmox node for the core services used by this project: MinIO, ChromaDB, and a simple Model Repository.

Run these directly on a Proxmox node as root (or with sudo). They assume a storage named `local-lvm` and a network bridge `vmbr0` by default. Adjust via environment variables.

#### MinIO

Create:
```bash
sudo VMID=201 HOSTNAME=minio IPADDR=10.0.0.100 \
  STORAGE=local-lvm BRIDGE=vmbr0 GATEWAY=10.0.0.1 \
  MINIO_ROOT_USER=minioadmin MINIO_ROOT_PASSWORD=change_me \
  ./scripts/containers/create_minio_lxc.sh
```
- Service listens on 9000 (S3) and 9001 (console)
- Data directory: `/data/minio`

#### ChromaDB

Create:
```bash
sudo VMID=202 HOSTNAME=chromadb IPADDR=10.0.0.101 \
  STORAGE=local-lvm BRIDGE=vmbr0 GATEWAY=10.0.0.1 \
  CHROMA_PORT=8000 \
  ./scripts/containers/create_chromadb_lxc.sh
```
- Service: `chroma run --host 0.0.0.0 --port $CHROMA_PORT --path /var/lib/chroma`

#### Model Repository

Create:
```bash
sudo VMID=203 HOSTNAME=model-repo IPADDR=10.0.0.102 \
  STORAGE=local-lvm BRIDGE=vmbr0 GATEWAY=10.0.0.1 \
  HTTP_PORT=8080 MODEL_ROOT=/srv/models \
  ./scripts/containers/create_model_repo_lxc.sh
```
- Serves static files from `MODEL_ROOT` via nginx on `HTTP_PORT`

#### Destroy a container
```bash
sudo ./scripts/containers/destroy_lxc.sh <VMID>
```

#### Notes
- Templates: The scripts use `debian-12-standard_12.2-1_amd64.tar.zst` and will download it to `local:vztmpl` if missing.
- Networking: Static IP is configured via Proxmox LXC config; ensure your bridge and subnet are correct.
- Privilege: By default containers are unprivileged (`UNPRIVILEGED=1`). Set `UNPRIVILEGED=0` to create privileged containers if needed.
- Storage: Adjust `STORAGE` and `DISK_GB` to match your Proxmox storage configuration.