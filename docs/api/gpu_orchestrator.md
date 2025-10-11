## GPU Orchestrator

Manages GPU job submission across Lightning.ai, Google Colab, and Paperspace with failover and quota awareness.

### Class: `GPUOrchestrator`
- `__init__(lightning_api_key: str | None = None, paperspace_api_key: str | None = None)`
- `submit_embedding_job(payload: dict) -> str`
  - Returns `job_id`
- `get_job_status(job_id: str) -> JobStatus`
- `cancel_job(job_id: str) -> bool`

### Strategy
- Chooses provider based on quotas, reliability, and job size
- Retries on transient failures; queues when none available

### Example
```python
from src.pipeline.gpu_orchestrator import GPUOrchestrator

orchestrator = GPUOrchestrator()
job_id = orchestrator.submit_embedding_job({
    "model": "sentence-transformers/all-MiniLM-L6-v2",
    "minio_uri": "s3://bucket/path/to/chunks.jsonl",
    "output_uri": "s3://bucket/path/to/embeddings.jsonl",
})
status = orchestrator.get_job_status(job_id)
print(status.state)
```