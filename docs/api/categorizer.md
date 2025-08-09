## Categorizer

Assigns labels to chunks for routing and collection management.

### Class: `ContentCategorizer`
- `categorize(chunks: list[Chunk]) -> list[Label]`

### Example
```python
from src.pipeline.categorizer import ContentCategorizer

cat = ContentCategorizer()
labels = cat.categorize(chunks)
```