## Retrieval & Reranking

Capabilities:
- Semantic similarity search (vector-only)
- Hybrid keyword + semantic search
- Multimodal search (conceptual)

### Example: Semantic Search
```python
from src.pipeline.retrieval_system import RetrievalSystem

retriever = RetrievalSystem(chromadb_host="10.0.0.101")
results = retriever.semantic_search(query="transformer architectures", top_k=5)
for r in results:
    print(r.score, r.metadata.get("source"))
```

### Example: Hybrid Search
```python
results = retriever.hybrid_search(query="GPU quota failover design", top_k=10)
```