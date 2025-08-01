# GPU-Accelerated Data Pipeline

A comprehensive, multimodal data ingestion and retrieval system that leverages free GPU services (Lightning.ai, Google Colab, Paperspace) for embedding generation, with local infrastructure management via Proxmox LXC containers.

## 🏗️ Architecture Overview

**Interface**: Gradio Web UI (Primary Control Hub)
- Data upload and processing control
- GPU service selection and monitoring  
- Real-time search and retrieval
- System health monitoring

**Infrastructure**: Proxmox LXC Containers
- **MinIO LXC**: S3-compatible object storage
- **ChromaDB LXC**: Vector database for embeddings
- **Model Repository LXC**: Local HuggingFace model cache

**GPU Services**: External Processing
- **Lightning.ai**: Primary GPU service (22 free GPU hours/month)
- **Google Colab**: Worker notebook integration  
- **Paperspace**: Container-based job execution
- **Task Queuing**: When no GPU services available, tasks are queued for later processing

## 🚀 Key Features

- **Multimodal Ingestion**: Text, code, images, PDFs
- **Intelligent Preprocessing**: Content-aware chunking, OCR, categorization
- **GPU Orchestration**: Automatic service selection, failover, task queuing, quota tracking
- **Advanced Search**: Semantic similarity, hybrid keyword-semantic, multimodal (conceptual)
- **Real-time Monitoring**: Live job status, service health, storage metrics

## 📁 Project Structure

```
├── docs/                    # Comprehensive documentation
│   ├── 00_overview.md       # High-level architecture
│   ├── 01_infrastructure/   # LXC containers, GPU services, environment
│   └── 02_pipeline/         # Data processing workflow
├── src/
│   ├── config/              # Configuration and dependencies
│   │   ├── requirements.txt # Python dependencies
│   │   └── .env.example     # Environment variables template
│   ├── main.py             # Gradio application entry point
│   └── pipeline/           # Core processing modules
│       ├── gpu_orchestrator.py    # GPU service management
│       ├── embedding_generator.py # Embedding coordination
│       ├── storage_manager.py     # MinIO/ChromaDB interface
│       ├── data_preprocessor.py   # Content preprocessing
│       ├── categorizer.py         # Content classification
│       └── retrieval_system.py    # Search and ranking
└── scripts/                # Utility and setup scripts
```

## 🛠️ Quick Start

1. **Setup Environment**:
   ```bash
   cp src/config/.env.example .env
   # Edit .env with your LXC container IPs and GPU service API keys
   pip install -r src/config/requirements.txt
   ```

2. **Launch Application**:
   ```bash
   python src/main.py
   ```

3. **Access Interface**: 
   - Open browser to `http://localhost:7860` (or configured host/port)

## 📖 Documentation

- **[Architecture Overview](docs/00_overview.md)**: System design and components
- **[Infrastructure Setup](docs/01_infrastructure/)**: LXC containers and GPU services  
- **[Pipeline Workflow](docs/02_pipeline/)**: Data processing and embedding generation

## 🔧 Configuration

Key environment variables (see `.env.example`):

```bash
# LXC Container Endpoints
MINIO_ENDPOINT=http://10.0.0.100:9000
CHROMADB_HOST=10.0.0.101
MODEL_REPO_ENDPOINT=http://10.0.0.102:8080

# GPU Service API Keys
LIGHTNING_API_KEY=your_lightning_key
PAPERSPACE_API_KEY=your_paperspace_key

# Gradio Interface
GRADIO_HOST=0.0.0.0
GRADIO_PORT=7860
```

## 🎯 Use Cases

- **Code Documentation**: Ingest codebases, search by functionality
- **Research Paper Analysis**: PDF processing with semantic search
- **Image Collection Management**: OCR + visual similarity search
- **Knowledge Base Creation**: Mixed content with intelligent categorization

## 🚧 Current Status

This is a comprehensive architectural blueprint with core components implemented. The system demonstrates:
- ✅ Complete Gradio interface structure
- ✅ GPU orchestration framework  
- ✅ Embedding generation pipeline
- ✅ Vector search and retrieval
- ⚠️  GPU service job scripts (Lightning, Colab, Paperspace) need completion
- ⚠️  Storage manager needs MinIO/ChromaDB integration testing

## 📄 License

[Specify your license]

## 🤝 Contributing

[Contribution guidelines]