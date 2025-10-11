## Usage Guide

### 1) Environment Setup
```bash
cp src/config/.env.example .env
pip install -r src/config/requirements.txt
```

### 2) Launch Gradio App
```bash
python src/main.py
# or programmatically
# from src.main import launch_app
# launch_app(host="0.0.0.0", port=7860)
```

### 3) Ingest Data (Programmatic)
```python
from src.pipeline.data_preprocessor import DataPreprocessor
from src.pipeline.categorizer import ContentCategorizer
from src.pipeline.embedding_generator import EmbeddingGenerator
from src.pipeline.gpu_orchestrator import GPUOrchestrator
from src.pipeline.storage_manager import StorageManager

pre = DataPreprocessor()
cat = ContentCategorizer()
orchestrator = GPUOrchestrator()
engine = EmbeddingGenerator(orchestrator)
store = StorageManager(minio_endpoint="http://10.0.0.100:9000", chromadb_host="10.0.0.101")

chunks = pre.preprocess_path("./samples/notes.pdf")
labels = cat.categorize(chunks)
embeddings = engine.generate_for_chunks(chunks, model="all-MiniLM-L6-v2")
engine.persist(embeddings)
```

### 4) Search
```python
from src.pipeline.retrieval_system import RetrievalSystem

retriever = RetrievalSystem(chromadb_host="10.0.0.101")
results = retriever.semantic_search("GPU orchestration failover", top_k=5)
for r in results:
    print(r.score, r.metadata.get("source"))
```