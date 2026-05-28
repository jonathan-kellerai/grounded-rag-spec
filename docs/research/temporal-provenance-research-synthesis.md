# Temporal Provenance Research Synthesis

**Grounded RAG Deep Research Mission: Bitemporal Models, PROV Derivation Chains, and Time-Aware Retrieval**

- **Date:** 2026-03-26
- **Scope:** Three interconnected research threads, 20+ papers from 1986–2026
- **Objective:** Identify academic foundations and transformative ideas for making Grounded RAG's code-RAG system temporally aware — capable of tracking when evidence was valid, when the system learned it, and how derived answers relate to their source spans

---

## Executive Summary

Three decades of database theory, a W3C provenance standard, and a wave of 2024–2025 RAG papers converge on a single insight: **a knowledge system that cannot say *when* something was true, *when it learned* that truth, and *how* an answer was derived from evidence is answering questions it doesn't actually understand.**

For a code-RAG system like Grounded RAG, the practical stakes are high.
Code changes.
A function that existed in commit `a1b2c3` may be gone in `d4e5f6`.
An answer grounded in a stale evidence span is not just imprecise — it is actively misleading.
The research below offers three complementary frameworks for fixing this:

1. **Bitemporal data models** — the formal machinery for tracking both world-time and system-time on every stored fact.
2. **W3C PROV-DM** — a standard graph vocabulary for tracing derivation chains from raw evidence to generated answer.
3. **Temporal RAG** — a body of 2024–2025 engineering work showing how to build these ideas into retrieval-augmented generation systems today.

---

## Part 1: Bitemporal Data Models for Knowledge Systems

### What Bitemporality Is

A bitemporal database associates every stored fact with two independent time axes:

- **Valid time** (also called *application time*): the period during which the fact was true in the modeled world. For code, this is "from which commit to which commit did this function exist in this form."
- **Transaction time** (also called *system time*): the period during which the database held this version of the fact. For code-RAG, this is "from when until when did the index contain this evidence span."

These are orthogonal. A fact can be loaded into the system long after it became true (late ingestion), or it can remain in the system after it stops being true (stale index). A bitemporal model records both dimensions, enabling queries like: "What did the system *know* as of index-time T₁ about facts that were *valid* at commit-time T₂?"

### Key Terminology

| Term | Meaning |
| --- | --- |
| Valid time (VT) | When the fact held in the real world / codebase |
| Transaction time (TT) | When the system recorded the fact |
| Bitemporal tuple | A fact tagged with `[VT_start, VT_end, TT_start, TT_end]` |
| Temporal sequenced semantics | Query semantics that respect both time axes simultaneously |
| Point-in-time query | Retrieve facts valid at a specific VT and/or TT coordinate |
| Snapshot isolation | View the database as it existed at a given TT |

### Top Papers

**1. Semantics of Time-Varying Information**
Jensen, C.S. and Snodgrass, R.T. | 1996 | Semantic Scholar: [link](https://www.semanticscholar.org/paper/Semantics-of-Time-Varying-Information-Jensen-Snodgrass/6ca19063bc9a34ac28b98b188036145131172a8c)

The foundational theoretical treatment of temporal database semantics by the two researchers who defined the field.
Snodgrass introduced the valid-time / transaction-time taxonomy that all subsequent work builds on.
The paper formalizes what it means for a database to be "temporally sequenced" — that queries and constraints respect both time dimensions.
For Grounded RAG: this is the mathematical basis for any claim that an evidence span is "currently valid."

**2. Temporal and Real-Time Databases: A Survey**
Ozsoyoglu, G. and Snodgrass, R.T. | 1995 | Semantic Scholar: [link](https://www.semanticscholar.org/paper/Temporal-and-Real-Time-Databases:-A-Survey-%C3%96zsoyoglu-Snodgrass/d2c0b538097e34b75878210da89fe390acdab226)

Comprehensive survey that established the vocabulary for the entire field.
Distinguishes valid time, transaction time, user-defined time, and bitemporal models.
The taxonomy here is directly portable to code retrieval: every evidence chunk in a vector store can be treated as a bitemporal relation.

**3. Data Models with Multiple Temporal Dimensions: Completing the Picture**
Carlo, Montanari et al. | Semantic Scholar: [link](https://www.semanticscholar.org/paper/Data-Models-with-Multiple-Temporal-Dimensions:-the-Carlo-Montanari/4c28340d4470b83bf584840fba5019e9bddb402e)

Extends the two-axis model to systems with additional temporal dimensions (e.g., "availability time" — when data was published externally vs. when it was ingested).
For a code RAG, availability time maps naturally to CI/CD publish time, distinct from commit time and index time.

**4. Bitemporal Property Graphs to Organize Evolving Systems**
Rost, C., Fritzsche, P., Schons, L., Zimmer, M., Gawlick, D., Rahm, E. | 2021 | arXiv: [2111.13499](https://arxiv.org/abs/2111.13499) | DOI: [10.48550/arXiv.2111.13499](https://doi.org/10.48550/arXiv.2111.13499)

Oracle and University of Leipzig collaboration that operationalizes bitemporal theory for property graphs (the data model underlying Neo4j and similar systems).
Delivers: a bitemporal property graph model (TPGM+), a temporal graph query language, and a prototype called BiTeGra.
**Directly applicable to Grounded RAG**: code repositories are naturally graphs (call graphs, module dependency graphs) and this paper shows how to stamp every edge and node with both valid-time and transaction-time intervals.

**5. Time Travel with the BiTemporal RDF Model (BiTRDF)**
MDPI Mathematics, 2025 | [link](https://www.mdpi.com/2227-7390/13/13/2109)

Adds valid time and transaction time to standard RDF triples, making every semantic triple `(subject, predicate, object, VT_start, VT_end, TT_start, TT_end)`.
Enables SPARQL-style queries that travel to any historical or current state.
Bridges graph-structured knowledge with temporal theory; the concept ports directly to embedding metadata schemas.

**6. LiveVectorLake: A Real-Time Versioned Knowledge Base Architecture for Streaming Vector Updates and Temporal Retrieval**
Prajapati, T. | 2025 | arXiv: [2601.05270](https://arxiv.org/abs/2601.05270)

**The most directly engineering-applicable paper in this thread.**
Proposes dual-tier storage: hot-tier vector indices (Milvus/HNSW) for current-knowledge queries, cold-tier columnar versioning (Delta Lake/Parquet) for historical snapshots.
Key mechanism: SHA-256 content-addressable chunk identity — only changed chunks are re-embedded, eliminating full re-indexing on code updates.
Performance: 10–15% re-processing on updates vs. 100% for naive re-index; sub-100ms current retrieval; sub-2s historical temporal queries with ACID consistency.
For Grounded RAG: this is a build-ready blueprint for a bitemporal vector store over a code corpus.

### Transformative Idea 1: Content-Addressed Bitemporal Chunk Identity

Every evidence span in Grounded RAG's index can be treated as a bitemporal tuple:

```
ChunkRecord {
  id:           SHA-256(file_path + line_range + content),
  valid_start:  git_commit_sha (when this version of the code appeared),
  valid_end:    git_commit_sha | null (when it was changed/deleted, null = current),
  tx_start:     index_timestamp (when Grounded RAG ingested it),
  tx_end:       index_timestamp | null (when Grounded RAG replaced/expired it),
  embedding:    [...384 dims...],
  content:      "...",
}
```

This four-timestamp tuple on every chunk makes it possible to answer: "Was this evidence span valid when the question was asked, and did the system know about it by then?"

---

## Part 2: W3C PROV and Derivation Provenance

### What PROV-DM Is

The W3C PROV Data Model ([W3C TR](https://www.w3.org/TR/prov-dm/)) is a domain-agnostic formal vocabulary for expressing provenance — the origins, processes, and dependencies that explain how a digital artifact came to exist.
It defines three primitive types and five core relations.

### PROV-DM Primitives

**Types:**

- **Entity**: A thing (physical, digital, or conceptual) whose provenance is of interest. In RAG: a document chunk, an embedding, a retrieved context window, a generated answer.
- **Activity**: Something that happens over time and acts upon or produces entities. In RAG: an ingestion pipeline run, an embedding computation, a retrieval query, an LLM generation call.
- **Agent**: Something bearing responsibility for activities or entities. In RAG: the ingestion worker, the retrieval model, the LLM, the human developer who authored the source code.

**Core Relations:**

| Relation | Meaning | RAG Interpretation |
| --- | --- | --- |
| `wasGeneratedBy` | Entity produced by Activity at a point in time | Answer generated by LLM generation call |
| `wasDerivedFrom` | Entity created from/based on another entity | Answer derived from context window derived from chunk |
| `wasInformedBy` | Activity depended on another Activity | Generation informed by retrieval |
| `wasAttributedTo` | Entity accountability ascribed to Agent | Answer attributed to LLM model version |
| `actedOnBehalfOf` | Agent delegating to another Agent | Embedder acting on behalf of ingestion pipeline |

### Key Papers

**7. PROV-DM: The PROV Data Model**
Moreau, L. et al. | W3C Recommendation, 2013 | [https://www.w3.org/TR/prov-dm/](https://www.w3.org/TR/prov-dm/)

The normative specification itself.
The critical insight for RAG: `wasDerivedFrom` is not automatically derivable from following `wasGeneratedBy` and `used` chains when there are multiple inputs and outputs — you must record it explicitly.
For Grounded RAG: the answer to a question is not automatically traced to a specific span just because that span appeared in the context window; you need an explicit `wasDerivedFrom` link tagged at generation time.

**8. The W3C PROV Family of Specifications for Modelling Provenance Metadata**
Moreau, L. and Groth, P. | 2013 | EDBT Proceedings | ACM: [10.1145/2452376.2452478](https://dl.acm.org/doi/10.1145/2452376.2452478)

Describes the full PROV family: PROV-DM (data model), PROV-O (OWL ontology), PROV-N (notation), PROV-XML, PROV-AQ (access/query).
The PROV-O serialization is particularly relevant because it makes every provenance graph queryable via SPARQL — enabling questions like "find all answers that were derived from evidence spans that are now expired."

**9. Supporting Better Insights of Data Science Pipelines with Fine-grained Provenance**
Chapman, A., Lauro, L., Missier, P., Torlone, R. | 2023/2024 | ACM Transactions on Database Systems | arXiv: [2310.18079](https://arxiv.org/abs/2310.18079)

Applies PROV to ML data preparation pipelines, defining provenance semantics for common transformation operators (filter, join, aggregate, split) as PROV templates.
Develops an algorithm for capturing provenance from observable input/output pairs — generalizes to any black-box pipeline stage.
For Grounded RAG: each chunking strategy, each embedding call, each reranking pass can be wrapped in a PROV template, making the derivation chain from raw code file to final answer queryable.

**10. Provenance Tracking in Large-Scale Machine Learning Systems (yProv4ML)**
Padovani, G., Anantharaj, V., Fiore, S. | 2025 | arXiv: [2507.01075](https://arxiv.org/abs/2507.01075)

Introduces yProv4ML, a library that instruments ML training pipelines to emit W3C PROV-compliant JSON provenance records.
Uses both W3C PROV and the ProvML extension that specializes PROV for ML contexts (model versions, hyperparameters, training runs).
For Grounded RAG: yProv4ML's pattern — instrument every pipeline stage to emit structured provenance records at completion — is directly portable to the ingestion and generation pipeline.

**11. Temporal Provenance Model (TPM): Model and Query Language**
Beheshti, S.M.R., Motahari-Nezhad, H.R., Benatallah, B. | 2012 | arXiv: [1211.5009](https://arxiv.org/abs/1211.5009)

**The critical bridge paper** between Parts 1 and 2 of this synthesis.
Identifies the core weakness in all prior provenance models: "existing provenance models treat time as a second class citizen — as an optional annotation."
Introduces **timed folders** (temporal containers for provenance objects) and **timed paths** (representations of how provenance graphs evolve over time).
Implements on FPSPARQL for large-scale temporal provenance graph queries.
For Grounded RAG: this paper establishes that provenance graphs themselves must be bitemporal — not just the evidence they point to.

**12. From Lossy to Verified: A Provenance-Aware Tiered Memory for Agents (TierMem)**
Zhu, Q., Chen, S., Yu, R., Wu, Z., Wang, B. | 2026 | arXiv: [2602.17913](https://arxiv.org/abs/2602.17913)

**The most forward-looking paper in this thread.**
Solves the "write-before-query barrier": when you compress memory at write time, you cannot know which details will matter at query time — so compressed summaries omit things that later turn out to be critical.
Architecture: Tier-1 = compressed summary index with explicit provenance pointers (ρ) to Tier-2 = immutable raw log store.
Escalation mechanism: a learned router decides, at query time, whether to answer from Tier-1 summaries or escalate to Tier-2 raw pages using provenance pointers as warm-start hints.
For Grounded RAG: this is the right architecture for a system that must produce *verifiable* answers — every answer cites summaries, every summary points back to raw spans, every raw span is bitemporal.

### Transformative Idea 2: The Derivation Chain as a First-Class Object

A PROV derivation chain for one Grounded RAG answer looks like:

```
RawCodeFile (entity, valid: [commit_A, commit_B])
  |-- wasGeneratedBy --> IngestRun_2026_03_01 (activity)
  |
ChunkSpan_abc123 (entity, tx: [2026-03-01, present])
  |-- wasDerivedFrom --> RawCodeFile
  |-- wasGeneratedBy --> ChunkingActivity
  |
Embedding_abc123 (entity)
  |-- wasDerivedFrom --> ChunkSpan_abc123
  |-- wasGeneratedBy --> EmbedCall (activity, used bge-small-en-v1.5 via sentence-transformers)
  |
RetrievedContext (entity, query_time: 2026-03-26T14:00Z)
  |-- wasDerivedFrom --> [Embedding_abc123, Embedding_def456, ...]
  |-- wasGeneratedBy --> RetrievalQuery
  |
Answer (entity)
  |-- wasDerivedFrom --> RetrievedContext
  |-- wasGeneratedBy --> GenerationCall (activity, used claude-sonnet-4-6)
  |-- wasAttributedTo --> GroundedRagAgent
```

With this graph persisted, Grounded RAG can retroactively answer: "Which answers made in the last 30 days were derived from evidence spans that have since been invalidated by new commits?"

---

## Part 3: Temporal RAG and Time-Aware Retrieval

### The Problem Space

Standard RAG treats the knowledge corpus as a static snapshot.
Evidence chunks are embedded once and ranked by semantic similarity.
This fails in three ways for code-RAG:

1. **Semantic similarity is temporally blind**: a query about how `processPayment()` works will retrieve the most semantically similar chunk — which may be from 18 months ago.
2. **No stale-evidence signal**: the system cannot distinguish "this chunk is highly relevant" from "this chunk used to be highly relevant but was superseded."
3. **Implicit recency bias**: full re-indexing after every commit is prohibitively expensive for large repos, so stale evidence accumulates silently.

### Top Papers

**13. RAG Meets Temporal Graphs: Time-Sensitive Modeling and Retrieval for Evolving Knowledge (TG-RAG)**
Han, J., Cheung, A., Wei, Y., Yu, Z., Wang, X., Zhu, B., Yang, Y. | 2025 | arXiv: [2510.13590](https://arxiv.org/abs/2510.13590) | DOI: [10.48550/arXiv.2510.13590](https://doi.org/10.48550/arXiv.2510.13590)

Represents external knowledge as a **bi-level temporal graph**: fine-grained timestamped facts at the leaf level, hierarchical time summaries (week, month, quarter) at higher levels.
Retrieval uses both temporal and semantic relevance scores to select evidence.
Introduces ECT-QA, a benchmark for evaluating temporal question answering with incremental knowledge updates.
For Grounded RAG: the bi-level temporal graph over a code corpus would look like: leaf nodes = individual function/class spans with commit timestamps, internal nodes = module-level summaries covering contiguous time ranges.

**14. Right Answer at the Right Time — Temporal RAG via Graph Summarization (STAR-RAG)**
Zhu, Z., Liu, H., He, M., Luo, S. | 2025 | arXiv: [2510.16715](https://arxiv.org/abs/2510.16715) | DOI: [10.48550/arXiv.2510.16715](https://doi.org/10.48550/arXiv.2510.16715)

Builds a **time-aligned rule graph** over the knowledge base, then propagates temporal constraints from the question to narrow the retrieval search space.
Key result: enforcing temporal consistency during retrieval eliminates most temporally-inconsistent candidates, dramatically reducing token usage without sacrificing accuracy.
No model fine-tuning required — the constraint propagation operates at retrieval time.
For Grounded RAG: rule graphs over code are well-defined (function call graphs, module dependency graphs are explicit); temporal constraints from questions ("how does the auth system work" could be constrained to HEAD or a specific release tag) are queryable.

**15. T-GRAG: A Dynamic GraphRAG Framework for Resolving Temporal Conflicts and Redundancy**
Li, D., Niu, Y., Ai, Y., Zou, X., Qi, B., Liu, J. | 2025 | arXiv: [2508.01680](https://arxiv.org/abs/2508.01680) | DOI: [10.48550/arXiv.2508.01680](https://doi.org/10.48550/arXiv.2508.01680)

Specifically designed for cases where the knowledge base contains **conflicting versions of the same fact** across time.
Three-layer retrieval mechanism: temporal KG layer, query decomposition layer, interactive retriever.
The **temporal conflict resolution** component is directly applicable to code-RAG, where a function may be defined differently across multiple branches or commits simultaneously.

**16. Plan of Knowledge (PoK): RAG for Temporal Knowledge Graph QA**
Qian, X., Zhang, Y., Zhao, Y., Zhou, B., Sui, X., Yuan, X. | 2025 | arXiv: [2511.04072](https://arxiv.org/abs/2511.04072)

Introduces a **Temporal Knowledge Store (TKS)** and contrastive retrieval that selects facts based on both semantic and temporal alignment jointly.
The "Plan of Knowledge" decomposes complex temporal questions into sub-objectives before retrieval, ensuring each sub-objective retrieves temporally coherent evidence.
For Grounded RAG: question decomposition before retrieval — rather than retrieving for the whole question at once — is especially important for code questions that span multiple subsystems with different change histories.

**17. VersionRAG: Version-Aware Retrieval-Augmented Generation for Evolving Documents**
Huwiler, D., Stockinger, K., Fürst, J. | 2025 | arXiv: [2510.08109](https://arxiv.org/abs/2510.08109)

**The most directly applicable temporal RAG paper to Grounded RAG's code domain.**
Addresses RAG over versioned technical documentation (API docs, release notes) — structurally identical to code-RAG.
Standard RAG achieves 58–64% accuracy on version-sensitive questions; VersionRAG achieves 90%.
Core mechanism: a version-aware graph index captures version sequences, content boundaries, and change diffs between versions.
For implicit change detection (questions where the version constraint isn't stated explicitly), VersionRAG achieves 60% where all baselines fail entirely.

**18. Solving Freshness in RAG: A Simple Recency Prior and the Limits of Heuristic Trend Detection**
Grofsky, M. | 2025 | arXiv: [2509.19376](https://arxiv.org/abs/2509.19376)

Experiments on cybersecurity intelligence — a domain with similarly high freshness requirements as code.
Finds that a **simple recency prior** (fuse cosine similarity score with a half-life decay function over document age) achieves perfect accuracy on freshness tasks.
Negative result equally important: clustering-based heuristics for topic evolution detection fail completely (0.08 F1), suggesting that trend detection requires structured temporal models rather than statistical heuristics.
For Grounded RAG: the simplest effective baseline for freshness is a half-life decay term in the scoring function — implementable in one line on top of the existing reranker.

**19. Temporal Reasoning with LLMs Augmented by Evolving Knowledge Graphs (EvoReasoner)**
Lin, J., Wang, S., Guo, X., Shun, J., Zhu, Y. | 2025 | arXiv: [2509.15464](https://arxiv.org/abs/2509.15464)

Demonstrates that an 8B-parameter model with proper temporal KG augmentation matches the performance of a 671B model from seven months later — the temporal reasoning augmentation substitutes for 83x model scale.
EvoKG component: incrementally updates the knowledge graph from unstructured documents with **confidence-based contradiction resolution** (when two facts conflict, resolve by evidence confidence and temporal recency).
For Grounded RAG: contradiction resolution is critical for code where the same symbol (class name, function signature) may appear differently in multiple contexts.

**20. A Survey on Temporal Knowledge Graph: Representation Learning and Applications**
Cai, L., Mao, X., Zhou, Y., Long, Z., Wu, C., Lan, M. | 2024 | arXiv: [2403.04782](https://arxiv.org/abs/2403.04782)

Comprehensive taxonomy of temporal knowledge graph methods: snapshot-based models (one graph per time step), interval-based models (facts valid over intervals), streaming models (continuous update).
For Grounded RAG: the interval-based model is most appropriate for code — each fact (this function exists, this class implements this interface) is valid over a commit interval, not a discrete timestamp.

---

## Part 4: Cross-Domain Synthesis

### The Compound Architecture: Bitemporal-PROV-Temporal-RAG

These three bodies of research are not independent — they compose into a single coherent architecture for a temporally-honest code-RAG system:

```
LAYER 1: BITEMPORAL CHUNK STORE
  Every evidence span tagged with (valid_start, valid_end, tx_start, tx_end)
  Content-addressed by SHA-256(path + line_range + content_hash)
  Dual-tier: hot vector index for current, cold columnar store for history
  [Source: LiveVectorLake arXiv:2601.05270 + Bitemporal Property Graphs arXiv:2111.13499]

LAYER 2: PROV DERIVATION GRAPH
  Every pipeline stage emits PROV-compliant records
  wasGeneratedBy links: chunk → ingest run, embedding → embed call, answer → generation
  wasDerivedFrom links: answer → context window → chunks → raw files
  Temporal Provenance Model (TPM) adds valid/tx timestamps to all PROV nodes
  [Source: PROV-DM W3C TR + TPM arXiv:1211.5009 + TierMem arXiv:2602.17913]

LAYER 3: TEMPORAL RETRIEVAL
  At query time, fuse semantic similarity with temporal validity score
  Decay function: score = cosine_sim × exp(-λ × age_in_commits)
  Hard filter: reject chunks where valid_end < HEAD (expired evidence)
  Version routing: when query specifies a commit/tag, route to historical tier
  [Source: Freshness in RAG arXiv:2509.19376 + VersionRAG arXiv:2510.08109 + STAR-RAG arXiv:2510.16715]

LAYER 4: TEMPORAL CONFLICT RESOLUTION
  When multiple chunks describe the same symbol with conflicting content,
  resolve by: (1) temporal recency, (2) evidence confidence, (3) branch priority
  Surface conflicts to caller rather than silently picking one
  [Source: T-GRAG arXiv:2508.01680 + EvoReasoner arXiv:2509.15464]
```

### The Most Transformative Ideas

**Idea A: The Stale-Evidence Tombstone**

Every time a code commit invalidates an evidence span (a function is deleted, renamed, or substantially rewritten), generate a **tombstone record**: a PROV entity with `wasInvalidatedBy` pointing to the commit activity. At retrieval time, tombstones act as negative signals in reranking. A chunk retrieved by cosine similarity whose tombstone is more recent than its valid_end gets penalized rather than promoted.

This is not in any single paper — it synthesizes LiveVectorLake's content-addressing, TPM's timed provenance graph, and T-GRAG's temporal conflict resolution into a novel mechanism specifically for code-RAG.

**Idea B: Point-in-Time Answer Reproducibility**

A question asked of Grounded RAG at time T should be reproducible: given the same question and the same system clock T, the system should produce the same answer by routing all retrieval to the bitemporal snapshot valid at (tx_time = T). This is standard database snapshot isolation applied to RAG. The LiveVectorLake architecture supports this natively; the PROV graph enables auditing which snapshot was used.

**Idea C: Derivation-Chain Staleness Propagation**

If any node in an answer's `wasDerivedFrom` chain has expired valid_end, the answer itself is flagged as potentially stale. This propagates temporal uncertainty upward through the provenance graph — the answer knows it may be wrong because its evidence may have changed. The TierMem architecture (arXiv:2602.17913) implements a version of this as "escalation routing": when summary provenance is stale, escalate to raw pages before answering.

**Idea D: Commit-Scoped Temporal Context Injection**

When a query arrives with an implicit temporal context (e.g., from a developer working on branch `feat/new-auth`), the retrieval layer can automatically constrain valid_time to include only commits reachable from that branch's HEAD. This is temporal scoping — the system answers in the context of the developer's reality, not the global HEAD. No paper does exactly this for code-RAG, but it follows directly from TG-RAG's bi-level temporal graph (arXiv:2510.13590) and STAR-RAG's temporal constraint propagation (arXiv:2510.16715).

---

## Key Terms Reference

| Term | Definition | Source |
| --- | --- | --- |
| Valid time | When a fact was true in the world | Snodgrass 1995 |
| Transaction time | When the system recorded the fact | Snodgrass 1995 |
| Bitemporal tuple | Fact tagged with (VT_start, VT_end, TT_start, TT_end) | Jensen & Snodgrass 1996 |
| PROV Entity | A thing whose provenance is tracked | W3C PROV-DM |
| PROV Activity | A process that produces or uses entities | W3C PROV-DM |
| wasGeneratedBy | Entity produced by an activity | W3C PROV-DM |
| wasDerivedFrom | Entity derived from another entity | W3C PROV-DM |
| Timed folder | PROV container with temporal extent | TPM arXiv:1211.5009 |
| Timed path | PROV graph path with temporal evolution | TPM arXiv:1211.5009 |
| Content-addressed chunk | SHA-256(path + lines + content) = stable ID | LiveVectorLake arXiv:2601.05270 |
| Hot/cold tier | Current vectors (fast) + historical snapshots (cheap) | LiveVectorLake arXiv:2601.05270 |
| Recency prior | Half-life decay on chunk age in retrieval scoring | Freshness RAG arXiv:2509.19376 |
| Version routing | Directing historical queries to cold tier | LiveVectorLake / VersionRAG |
| Temporal conflict | Same symbol described differently across commits | T-GRAG arXiv:2508.01680 |
| Escalation routing | Route to raw evidence when summary provenance is stale | TierMem arXiv:2602.17913 |
| Tombstone record | PROV entity marking invalidation of a prior entity | (synthesized) |

---

## Suggested Reading Order

For an engineer implementing Grounded RAG's temporal layer, read in this sequence:

1. **[PROV-DM W3C Spec](https://www.w3.org/TR/prov-dm/)** — 30 minutes. Learn the vocabulary. Everything else builds on it.
2. **[LiveVectorLake arXiv:2601.05270](https://arxiv.org/abs/2601.05270)** — The engineering blueprint for a bitemporal vector store.
3. **[VersionRAG arXiv:2510.08109](https://arxiv.org/abs/2510.08109)** — Closest analogue to code-RAG: versioned docs with explicit change tracking.
4. **[TPM arXiv:1211.5009](https://arxiv.org/abs/1211.5009)** — Why provenance graphs must themselves be temporal, not just annotated with time.
5. **[TierMem arXiv:2602.17913](https://arxiv.org/abs/2602.17913)** — The architecture that makes answers verifiable by preserving raw evidence behind summaries.
6. **[Freshness in RAG arXiv:2509.19376](https://arxiv.org/abs/2509.19376)** — The simplest effective baseline: add a recency decay term to your reranker.
7. **[T-GRAG arXiv:2508.01680](https://arxiv.org/abs/2508.01680)** — Temporal conflict resolution for when the same symbol lives in multiple versions simultaneously.
