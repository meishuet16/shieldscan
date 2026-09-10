# Local RAG with LanceDB

ShieldScan's default threat-intelligence retrieval path is local and account-free.

## Why LanceDB

The project needs semantic retrieval without requiring every contributor or reviewer to create a hosted vector-database account. LanceDB stores the vector index locally and can be replaced later through ShieldScan's provider abstraction.

## Setup

From `backend/`:

```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements-rag.txt
python scripts/build_threat_index.py
```

The first build downloads the configured sentence-transformers model and writes a local LanceDB index under `backend/data/lancedb/`. The index is intentionally ignored by git.

Then run the API normally:

```bash
uvicorn main:app --reload --port 8080
```

No LanceDB account, hosted database, service account, or vector-search API key is required.

## Retrieval providers

`SHIELDSCAN_RETRIEVAL_PROVIDER` supports:

- `lancedb` — default local semantic vector retrieval
- `local` — deterministic keyword fallback
- `vertex` — optional managed Vertex AI Search integration

If the LanceDB dependencies or index are unavailable, ShieldScan logs the condition and falls back to the provenance-bearing local corpus. Retrieval failure is never treated as evidence that an input is safe.

## Embedding model

Default:

`sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2`

The model is loaded locally through sentence-transformers. It can be replaced with `SHIELDSCAN_EMBEDDING_MODEL` without changing the retrieval API.

## What makes this RAG

For text and URL scans, ShieldScan retrieves semantically related threat-intelligence records before presenting the final evidence package. Retrieved records retain source name and source URL and are returned separately from Gemini's semantic fraud analysis.

The retrieval layer does not fabricate access to official databases. The current seed corpus is small and provenance-bearing; a future ingestion pipeline should expand it using verified public advisories while preserving publication metadata and source URLs.
