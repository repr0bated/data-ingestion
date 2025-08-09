## Data Preprocessor

Extracts and prepares content for embedding.

### Class: `DataPreprocessor`
- `preprocess_path(path: str | Path) -> list[Chunk]`
- `preprocess_bytes(data: bytes, modality: str, uri: str | None = None) -> list[Chunk]`
- `chunk_text(text: str, strategy: str = 'semantic', max_tokens: int = 512) -> list[Chunk]`

### Example
```python
from src.pipeline.data_preprocessor import DataPreprocessor

pre = DataPreprocessor()
chunks = pre.preprocess_path("./samples/image.png")
```