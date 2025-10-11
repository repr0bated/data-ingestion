## GPU Services

Supported services and their integration model.

### Lightning.ai
- API Key: `LIGHTNING_API_KEY`
- Usage: Submit containerized or script jobs; track runtime quotas
- Pattern:
  - Package workload (embedding generation) as a job
  - Poll job status via `GPUOrchestrator`

### Google Colab
- Job Model: Notebook-based worker
- Pattern:
  - Parameterize notebook with storage endpoints and model spec
  - Use callbacks/webhooks or polling for completion

### Paperspace
- API Key: `PAPERSPACE_API_KEY`
- Pattern:
  - Launch container with mounted storage creds
  - Stream logs; persist results to MinIO

### Quota and Failover
- `GPUOrchestrator` selects the best available service based on:
  - Remaining free hours/quotas
  - Historical reliability
  - Job size and modality requirements
- Automatic retry and queueing when no GPU is immediately available