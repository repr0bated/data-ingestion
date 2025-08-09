## Gradio UI

Entry point: `src/main.py`

### Public Interface
- `launch_app(host: str, port: int) -> None`
  - Starts the Gradio app with pages for Ingestion and Search

### Usage
```python
from src.main import launch_app

launch_app(host="0.0.0.0", port=7860)
```

### Pages and Events
- Ingestion: upload files, select GPU service strategy, submit jobs
- Search: free text query; choose semantic/hybrid; view results and metadata