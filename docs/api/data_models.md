## Data Models

### Document
- `id: str`
- `uri: str | Path`
- `modality: Literal['text','image','pdf','code']`
- `text: Optional[str]`
- `bytes: Optional[bytes]`
- `metadata: Dict[str, Any]`

### Chunk
- `id: str`
- `document_id: str`
- `text: str`
- `start_offset: int`
- `end_offset: int`
- `metadata: Dict[str, Any]`

### Embedding
- `id: str`
- `vector: List[float]`
- `dimensionality: int`
- `metadata: Dict[str, Any]`

### JobStatus
- `job_id: str`
- `state: Literal['queued','running','succeeded','failed','canceled']`
- `started_at: Optional[datetime]`
- `finished_at: Optional[datetime]`
- `logs_uri: Optional[str]`
- `error_message: Optional[str]`

### SearchResult
- `id: str`
- `score: float`
- `text: str`
- `metadata: Dict[str, Any]`