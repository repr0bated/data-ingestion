## Ingestion & Preprocessing

### Supported Modalities
- Text, code, PDFs, images

### Preprocessing
- Text extraction (OCR for images/PDF)
- Content-aware chunking
- Metadata extraction (source, timestamps, tags)

### Categorization
- Assigns labels/collections to chunks for routing

### Example
```python
from src.pipeline.data_preprocessor import DataPreprocessor
from src.pipeline.categorizer import ContentCategorizer

pre = DataPreprocessor()
cat = ContentCategorizer()

chunks = pre.preprocess_path("./docs/paper.pdf")
labels = cat.categorize(chunks)
for chunk, label in zip(chunks, labels):
    print(label.name, chunk.text[:120])
```