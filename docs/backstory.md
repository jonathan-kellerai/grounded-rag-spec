# Grounded RAG — Origin Story

- **Date:** 2026-03-25
- **Named by:** March Madness Telegram tournament (128 avatars, 32 candidates, 16-team bracket)
- **Championship:** Grounded RAG beat Ark in the final
- **Bracket path:** beat Leviathan → beat Reliquary → beat Tesseract → beat Ark

## The Name

**Matryoshka** (Russian: матрёшка) — nested dolls, each containing a smaller version inside.
The outermost doll is simple and decorative. Open it and there's another. And another.
Each layer reveals more complexity.

This maps perfectly to the architecture:
- **Outer doll**: The skill shell (one tool, 80 tokens)
- **Middle doll**: The RAG pipeline (ingestion, chunking, retrieval, assembly)
- **Inner doll**: The twin SLMs (embedder + reranker)

## The Concept

Current RAG systems are infrastructure-heavy:
- Dedicated vector databases (Pinecone, Weaviate, Qdrant)
- Separate embedding services
- Separate reranking services
- Complex orchestration (LangChain, LlamaIndex)
- Persistent state, configuration, monitoring

Grounded RAG collapses this into a single skill:
- The skill IS the RAG pipeline
- Embeddings via sentence-transformers BAAI/bge-small-en-v1.5 (384 dims, fully local)
- Reranking via sentence-transformers cross-encoder/ms-marco-MiniLM-L-6-v2 (fully local)
- Vector store: LanceDB (embedded, no server, persists to local disk)
- No external calls. No new services. Fully self-contained.

## The 16 Candidates

| Seed | Name | Fate |
|------|------|------|
| 1 | Grimoire | Lost Round of 16 |
| 2 | **Matryoshka** | **CHAMPION** |
| 3 | Leviathan | Lost Round of 16 |
| 4 | Basilisk | Lost Round of 16 |
| 5 | Obelisk | Lost Round of 16 |
| 6 | Colossus | Lost Round of 16 |
| 7 | Pandora | Lost Semifinals |
| 8 | Golem | Lost Round of 16 |
| 9 | Kraken | Lost Quarterfinals |
| 10 | Legion | Lost Quarterfinals |
| 11 | Grail | Lost Quarterfinals |
| 12 | Tesseract | Lost Semifinals |
| 13 | Labyrinth | Lost Round of 16 |
| 14 | Reliquary | Lost Quarterfinals |
| 15 | Ark | Runner-up (lost in Championship) |
| 16 | Singularity | Lost Round of 16 |

## Related Architecture

- **AI Provenance Spec**: Sister project (the deployment mechanism for skills like Grounded RAG)
- **sentence-transformers**: BAAI/bge-small-en-v1.5 (embedder) and cross-encoder/ms-marco-MiniLM-L-6-v2 (reranker) — fully local
- **ADR-015**: Cortex Architecture (Telegram as nervous system)
- **Governance Grimoire**: OPA/Rego policy-as-code (Chimera plan)
