## LXC Containers

Provision three Proxmox LXC containers. Suggested specs: 2 vCPU, 4–8GB RAM, 20–50GB disk each.

### MinIO
- Ports: 9000 (S3 API), 9001 (console)
- Env:
  - `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`
- Health:
  - `curl -sS http://<minio-ip>:9000/minio/health/live`

### ChromaDB
- Port: 8000 (if served via chromadb server) or embedded
- Health:
  - `curl -sS http://<chromadb-ip>:8000/healthz` (if exposed)

### Model Repository (HF Cache)
- Purpose: Local cache proxy for HuggingFace models
- Port: 8080 (example)
- Health:
  - `curl -sS http://<model-repo-ip>:8080/healthz`

### Network and Security
- Place LXC containers on a private VLAN
- Restrict inbound rules to app nodes only
- Backups/Snapshots recommended prior to upgrades