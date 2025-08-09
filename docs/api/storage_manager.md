## Storage Manager

Unified interface to MinIO (objects) and ChromaDB (vectors).

### Class: `StorageManager`
- `__init__(minio_endpoint: str, chromadb_host: str)`
- `put_object(bucket: str, key: str, data: bytes, content_type: str = 'application/octet-stream') -> str`
- `get_object(bucket: str, key: str) -> bytes`
- `upsert_embeddings(collection: str, embeddings: list[Embedding]) -> None`
- `query(collection: str, query_vector: list[float], top_k: int = 5) -> list[SearchResult]`

### Example
```python
from src.pipeline.storage_manager import StorageManager

store = StorageManager(minio_endpoint="http://10.0.0.100:9000", chromadb_host="10.0.0.101")
uri = store.put_object("artifacts", "chunks.jsonl", b"{}\n")
blob = store.get_object("artifacts", "chunks.jsonl")
```