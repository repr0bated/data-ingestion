## Environment Variables

Copy from template and adjust values.

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

Place in `.env` at the project root. Ensure network connectivity from the app host to the LXC IPs.