## GPU-Accelerated Data Pipeline: Architecture Overview

This system is a multimodal data ingestion and retrieval platform optimized for GPU-accelerated embedding generation. It orchestrates external free GPU services while persisting artifacts locally via Proxmox LXC-managed infrastructure.

### System Components
- **Interface: Gradio Web UI**
  - Uploads content, triggers processing, monitors jobs, and performs search
- **Infrastructure: Proxmox LXC containers**
  - `MinIO` (S3-compatible object storage)
  - `ChromaDB` (vector database)
  - `Model Repository` (local HuggingFace cache)
- **GPU Services**
  - `Lightning.ai`, `Google Colab`, `Paperspace`; automatic selection, failover, and quota tracking
- **Core Pipeline**
  - Preprocessing → Categorization → Embedding Generation → Storage → Retrieval/Reranking

### Data Flow (textual diagram)
1. User uploads data via Gradio UI
2. `DataPreprocessor` extracts text (OCR for images/PDFs) and chunkifies content
3. `ContentCategorizer` classifies chunks to route them to collections
4. `EmbeddingGenerator` schedules embedding jobs through `GPUOrchestrator`
5. Embeddings and metadata are written to `ChromaDB` and artifacts to `MinIO`
6. `RetrievalSystem` provides semantic, hybrid, and multimodal search

### Key Guarantees
- GPU service abstraction with retry/failover and quota-awareness
- Content-aware chunking for improved recall and precision
- Consistent storage interface for objects and vectors

### Related Documentation
- Infrastructure: `docs/01_infrastructure/README.md`
- Pipeline: `docs/02_pipeline/README.md`
- API Reference: `docs/api/README.md`