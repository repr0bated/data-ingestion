## Retrieval System

Provides semantic and hybrid search capabilities.

### Class: `RetrievalSystem`
- `__init__(chromadb_host: str)`
- `semantic_search(query: str, top_k: int = 5) -> list[SearchResult]`
- `hybrid_search(query: str, top_k: int = 10) -> list[SearchResult]`

### Example
```python
from src.pipeline.retrieval_system import RetrievalSystem

retriever = RetrievalSystem(chromadb_host="10.0.0.101")
results = retriever.semantic_search("vector databases for embeddings", top_k=5)
```