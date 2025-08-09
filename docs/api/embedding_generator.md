## Embedding Generator

Coordinates chunk batching and GPU job submission for embedding creation.

### Class: `EmbeddingGenerator`
- `__init__(orchestrator: GPUOrchestrator)`
- `generate_for_chunks(chunks: list[Chunk], model: str, batch_size: int = 64) -> list[Embedding]`
- `persist(embeddings: list[Embedding]) -> None`

### Example
```python
from src.pipeline.embedding_generator import EmbeddingGenerator
from src.pipeline.gpu_orchestrator import GPUOrchestrator

orchestrator = GPUOrchestrator()
engine = EmbeddingGenerator(orchestrator)
embeddings = engine.generate_for_chunks(chunks, model="all-MiniLM-L6-v2")
engine.persist(embeddings)
```