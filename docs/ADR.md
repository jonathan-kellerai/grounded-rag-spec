# Grounded RAG — Architecture Decision Records

> This file is an `ArchitectureDecisionRecord` registry as required by `docs/constitution.md §Canonical and Durable Objects`.
> Every constitution amendment and every change to a forced decision in `docs/v1-scope.md` must produce an entry here.
> Constitution amendments without a corresponding record are invalid.

---

## ADR-001: EvidenceSpan as the Canonical Epistemic Object (not Claim)

- **Status:** Accepted
- **Date:** 2026-03-25
- **Authors:** Skill Architect

### Context

Grounded RAG needed a first-class epistemic unit to anchor every served answer.
Two candidates were considered:

- `Claim` — a semantic proposition extracted from source text (e.g., "function X returns Y")
- `EvidenceSpan` — a source-anchored, versioned fragment with full provenance

Claim extraction requires an offline NLP pipeline and cannot run on the hot path.
It is also lossy: extraction errors corrupt downstream reasoning without a clean
fallback.

### Decision

The canonical epistemic object in v1 is **`EvidenceSpan`**, not `Claim`.

An `EvidenceSpan` is a source-anchored, versioned slice of content carrying:

- a bitemporal identity tuple: `(content_hash, valid_start_commit, valid_end_commit, tx_start, tx_end)`
- a `ProvenanceLedger`: hash-linked chain from source through chunk algorithm, embedding, reranking, to assembly position
- a `bpa_vector` and `uncertainty_interval` for Dempster-Shafer scoring
- a `confidence_tier`: `REASONABLE_SUSPICION`, `PREPONDERANCE`, or `BEYOND_REASONABLE_DOUBT`
- an `EpistemicStatus` recording dialectical conflict state (Pollock rebutting/undercutting/none)

`Claim`, `Entity`, and `Contradiction` are derived experimental objects — offline-only and feature-gated in v1.

### Rationale

- Replayability is a core invariant (constitution §Core Invariants rule 4).
  EvidenceSpan is directly observable in source; Claims are transformed artifacts
  that may not survive source mutations cleanly.
- The live path can be narrow without Claim extraction: retrieve → rerank → assemble → synthesize.
- Offline enrichment (claimification, contradiction detection) can be layered on top
  without changing the public answer contract.

### Consequences

- Every non-abstaining answer must expose cited EvidenceSpan references.
- Abstention is natural: no evidence → Abstain, not hallucination.
- v1 does not ship contradiction detection on the hot path (offline only).
- Future claim-native serving requires a constitution amendment.

---

## ADR-002: Three-State Answer Contract (Grounded / Partial / Abstain)

- **Status:** Accepted
- **Date:** 2026-03-25
- **Authors:** Skill Architect

### Context

How should Grounded RAG represent answer confidence to callers?

Options considered:

1. Single float confidence score (e.g., 0.87)
2. Binary: answer / no-answer
3. Three discrete states with explicit evidence thresholds

A single float score gives callers no actionable information unless they define
their own threshold. Binary answer/no-answer discards important partial-evidence
cases. Calibrated probability requires ground truth that does not exist at authoring time.

### Decision

Every response is exactly one of:

- **`Grounded`**: requires ≥2 independently anchored EvidenceSpans covering the core answer
  (or 1 self-contained span), no unresolved coverage gap, no active epistemic conflict,
  and all cited spans at `PREPONDERANCE` confidence tier or higher, with `extension_count = 0`.
- **`Partial`**: requires ≥1 anchored EvidenceSpan plus at least one of: coverage gap,
  unsupported inference step, active epistemic conflict, or no span reaching `PREPONDERANCE`.
- **`Abstain`**: mandatory when evidence is insufficient, relevant material is forbidden by
  policy, unresolved contradiction is present on a high-impact question, or the system is in
  degraded safety mode.

### Rationale

- Discrete states are machine-testable in benchmarks. Float scores are not.
- `Grounded` / `Partial` / `Abstain` maps directly to the Dempster-Shafer frame
  Θ = {Grounded, Partial, Abstain} used for internal uncertainty modeling.
- Abstention is a first-class answer, not a failure mode. This prevents hallucination by design.
- Changing the public answer contract is an amendment-level decision — deliberately expensive
  to discourage churn in the caller interface.

### Consequences

- Every non-abstaining answer must include: answer text, cited spans, coverage state,
  `EpistemicStatus` summary, `uncertainty_interval [Bel, Pl]`, and a snapshot id.
- The three states are frozen for v1 (§Evolution Boundaries — Must not evolve automatically).
- Callers get a deterministic state machine, not a probability to threshold.
- BPA frame and `ConfidenceTier` thresholds (`PREPONDERANCE` ≥0.65 Bel,
  `BEYOND_REASONABLE_DOUBT` ≥0.85 Bel) are fixed and cannot be adjusted without an ADR.

---

## ADR-003: Live-Path Narrowness — Online/Offline Split

- **Status:** Accepted
- **Date:** 2026-03-25
- **Authors:** Skill Architect

### Context

Many enrichments are valuable: claim extraction, contradiction detection, benchmark
generation, policy experiments, compaction, revocation rebuilds. The question was
which of these belong on the hot path vs. deferred to an offline layer.

The risk of a wide hot path: unpredictable latency, tight coupling between live
serving and research-quality components, difficulty reasoning about failure modes.

### Decision

The live path may only do:

1. Retrieve candidate evidence spans
2. Rerank
3. Assemble context
4. Synthesize answer
5. Emit citations and write a minimal audit record

The following are **offline-only** in v1:

- claim extraction
- contradiction consolidation
- benchmark generation
- policy experimentation
- compaction
- revocation cascade rebuilds

The system must always support **Boring Mode**: evidence-span retrieval only, fixed
synthesis template, no claim usage, no policy evolution, no dependency on offline-derived
objects. If higher-order machinery is impaired, the system falls back to Boring Mode
rather than failing open.

### Rationale

- The kill criterion requires beating a simpler baseline — a narrow hot path is closer
  to the baseline and easier to optimize.
- Offline enrichment is additive: it cannot break live serving if properly isolated.
- Boring Mode is an explicit safety guarantee, not an afterthought.

### Consequences

- v1 does not detect contradictions at serve time.
- The five-step online path is the falsifiable unit: if it doesn't win, the rest of
  the architecture is not earned (v1-scope.md §Smallest Falsifiable Loop).
- Circuit breakers for higher-order systems (policy promotion, derived-object generation,
  answering outside Boring Mode) are required at v1 launch.

---

## ADR-004: Repo-Scoped Corpus for v1

- **Status:** Accepted
- **Date:** 2026-03-25
- **Authors:** Skill Architect, Release Authority

### Context

Grounded RAG could ingest many source types: web pages, chat logs, Jira, Slack, email,
external enterprise systems, cross-repo shared memory. Each adds ingestion complexity,
auth surface, source trust policy requirements, and failure modes.

The risk: building a general-purpose knowledge system before the core RAG loop is validated.

### Decision

The v1 corpus is limited to:

- repo source files
- repo markdown and docs
- ADRs and design docs in-repo
- local config and specification files

**Explicitly excluded from v1:**
web crawling, chat logs, Jira, Slack, email, external enterprise systems, cross-repo
shared memory.

### Rationale

- The smallest falsifiable loop (v1-scope.md) requires only one repo's code and docs.
  If the system cannot win on local corpus, it has not earned broader sources.
- A deterministic, local corpus eliminates external auth, rate limits, and data freshness
  complexity from the initial validation.
- Source expansion is additive — new source classes require a new source-class policy
  (constitution §Core Invariants rule 2) and thus a natural gate on scope creep.

### Consequences

- v1 kill criterion (15% improvement over BM25 baseline) is measured against local corpus only.
- Adding any external source in v1 requires a constitution amendment naming the new
  source class policy.
- Federation, cross-repo memory, and external enterprise systems are explicitly deferred
  (v1-scope.md §Explicit Deferrals).

---

## ADR-005: MorphLLM morph-embedding-v4 and morph-rerank-v4 via an external MCP gateway (no new infrastructure)

- **Status:** Superseded by ADR-009
- **Date:** 2026-03-25
- **Authors:** Skill Architect

### Context

Grounded RAG requires embedding and reranking models for its RAG pipeline.
Options considered:

1. Local ONNX model (self-contained, no network dependency)
2. HuggingFace Inference API (external, requires key management)
3. OpenAI text-embedding-3 (external, cost-per-call)
4. **MorphLLM via an existing external MCP gateway** (morph-embedding-v4 + morph-rerank-v4)

The external MCP gateway is already running locally
and provides MorphLLM access. The embedding model is 1536-dim SoTA for code retrieval.

### Decision

Use **morph-embedding-v4** (1536 dims, SoTA code retrieval) and **morph-rerank-v4**
via the external MCP gateway. No new model services deployed.

Grounded RAG is entirely a skill — the outer shell is 80 tokens; the inner SLMs are
existing gateway tools.

### Rationale

- Zero new infrastructure. The gateway is already a dependency.
- morph-embedding-v4 is the best available code embedding model; the reranker
  (`morph-rerank-v4`) is trained for code relevance ranking.
- Keeping Grounded RAG as a pure skill (no server component) aligns with the nesting-doll
  architecture: the skill shell is the only visible surface.
- The vector store is ephemeral (in-memory) or local (SQLite + numpy) — no Pinecone,
  Weaviate, or Qdrant required.

### Consequences

- Grounded RAG requires an external MCP gateway to be running.
- Model hot-swap (e.g., replacing morph-embedding-v4 with a future model) requires a
  `BehavioralCertificate` and bisimulation-equivalence check before execution — deferred
  to post-v1 (v1-scope.md §Explicit Deferrals).
- Embedding dimension (1536) is frozen for v1. Changing it invalidates the existing index.

---

## ADR-006: Aegis Drop as Separate Deployment Sister (not Co-Located)

- **Status:** Accepted
- **Date:** 2026-03-25
- **Authors:** Skill Architect, Release Authority

### Context

Grounded RAG needs a deployment mechanism: skill registration with the external MCP gateway,
OPA/Rego Chimera validation before serving, policy bundle packaging, and version management.

Two options:

1. Self-contained: Grounded RAG handles its own deployment lifecycle.
2. **Separate sister project**: Aegis Drop owns all deployment concerns.

### Decision

**Aegis Drop** (the sister specification project) owns:

- skill registration with the gateway
- OPA/Rego Chimera pre-registration validation
- policy bundle assembly and promotion
- version lifecycle management

Grounded RAG owns RAG quality, answer contract, and provenance correctness only.

### Rationale

- Separation of concerns: a skill that can also deploy itself couples epistemic correctness
  to service mesh concerns in a single failure domain.
- Aegis Drop's Chimera plan (OPA/Rego validation before registration) acts as an independent
  gate — Grounded RAG cannot accidentally skip it if deployment is a separate system.
- Other skills can use Aegis Drop for deployment; the pattern is general.

### Consequences

- Grounded RAG cannot be served without Aegis Drop completing registration.
- The Chimera validation policy enforced by Aegis Drop
  must pass before any `PolicySnapshot` promotion.
- Interface boundary: Grounded RAG's output is a well-formed skill artifact;
  Aegis Drop's input is that artifact plus a signed policy bundle.

---

## ADR-007: Two-Layer RGMem Index for v1 (L0 + L1 Only)

- **Status:** Accepted
- **Date:** 2026-03-25
- **Authors:** Skill Architect

### Context

The full RGMem retrieval index has five layers:

- **L0**: BM25/token keyword retrieval over raw source chunks
- **L1**: statement-level embedding retrieval (BAAI/bge-small-en-v1.5 via sentence-transformers, 384 dims)
- **L2**: function-level retrieval
- **L3**: module-level retrieval
- **L4**: subsystem-cluster retrieval

Implementing all five layers in v1 would be premature before validating the core loop.

### Decision

V1 implements **L0 (BM25)** and **L1 (statement-level embeddings)** only.

L2, L3, and L4 are **reserved layer names** — they must not be occupied by ad-hoc
structures. Layer routing (which layers are queried per query topology class) is a
heuristic policy and may evolve within v1 without a constitution amendment.

### Rationale

- L0 + L1 is sufficient to beat the BM25-only baseline required by the kill criterion.
- Reserving L2–L4 by name prevents ad-hoc structures from colonizing those slots,
  keeping the upgrade path clean for v2.
- The kill criterion baseline uses BM25 only (k=5, no reranking) — L1 is the primary
  differentiator and must stand alone before L2–L4 are justified.

### Consequences

- The index schema must declare L2–L4 as reserved and reject any attempt to populate them in v1.
- Any deviation from L0+L1 in v1 requires an ADR naming the substitution and reason
  (v1-scope.md §Kill Criteria — Required baseline definition).
- L2–L4 implementation is an explicit deferral.
- The L1 embedding dimension is determined by the embedder choice (currently 384 dims per ADR-009) and must be encoded in the index schema at table creation. Changing the dimension is an index-destroying operation requiring a full source re-ingest — not a model swap. A model hot-swap that changes dimension is therefore a rebuild event (see ADR-010), not a behavioral swap subject to `BehavioralCertificate` alone.

---

## ADR-008: Dempster-Shafer BPA for Uncertainty (not Single Confidence Score)

- **Status:** Accepted
- **Date:** 2026-03-25
- **Authors:** Skill Architect

### Context

Uncertainty in retrieval-augmented generation has multiple independent dimensions:
evidence strength, coverage quality, source trust, epistemic conflict, synthesis
distance. A single float confidence score collapses all of these into one number,
losing the structure needed to route the right response to callers.

### Decision

Uncertainty is tracked internally as **six independent dimensions**:

- `evidence_strength`
- `coverage_quality`
- `source_trust`
- `epistemic_conflict` (tracks `conflict_type`, `conflict_degree`, `extension_count`
  per Dung argumentation semantics)
- `synthesis_distance`
- `bpa_combined` (Dempster-Shafer belief/plausibility interval after combining all
  cited span BPA vectors; Yager normalization applied when conflict mass K > 0.5)

**Publicly**, uncertainty is surfaced as:

- answer state (Grounded / Partial / Abstain)
- coverage state (one of six values)
- `EpistemicStatus` summary (`conflict_type` and `extension_count` at minimum)
- `uncertainty_interval` as `[Bel, Pl]` pair over frame Θ = {Grounded, Partial, Abstain}

V1 does not expose a single unified confidence float.

### Rationale

- Calibrated single-score confidence requires ground truth that does not exist at
  authoring time and is routinely miscalibrated in RAG systems.
- The three-state answer contract (ADR-002) maps directly onto the DST frame —
  BPA mass assignment makes the link between internal evidence and public state explicit.
- Dialectical conflict (epistemic_conflict) is a distinct signal from evidence scarcity —
  conflating them in one score produces incorrect routing.
- The `[Bel, Pl]` interval conveys both the belief floor and plausibility ceiling,
  which callers can use for threshold-based routing without the system guessing their threshold.

### Consequences

- BPA frame Θ = {Grounded, Partial, Abstain} and mass assignment formula are frozen in v1.
- `ConfidenceTier` thresholds are fixed: `REASONABLE_SUSPICION` ≥0.4, `PREPONDERANCE` ≥0.65 Bel,
  `BEYOND_REASONABLE_DOUBT` ≥0.85 Bel with `extension_count = 0`.
- Yager normalization (not Dempster's rule) is used when conflict mass K > 0.5 to avoid
  counter-intuitive mass concentration.
- Any change to the BPA frame or confidence thresholds requires a constitution amendment.

---

## ADR-009: Local sentence-transformers + LanceDB (Self-Contained, No External Calls)

- **Status:** Accepted
- **Date:** 2026-03-27
- **Authors:** Skill Architect
- **Supersedes:** ADR-005

### Context

ADR-005 chose MorphLLM morph-embedding-v4 and morph-rerank-v4 via the external MCP gateway
for embedding and reranking.
This created a hard runtime dependency: Grounded RAG could not function without the gateway running.
The fundamental project requirement is full self-containment — no external API calls,
no gateway dependency at inference time, portable across any environment.

Options reconsidered:

1. MorphLLM via an external MCP gateway (ADR-005) — requires gateway running, external network call
2. HuggingFace Inference API — external, requires key management, not self-contained
3. OpenAI text-embedding-3 — external, cost-per-call, not self-contained
4. **sentence-transformers with local ONNX/PyTorch models** — fully local, zero network calls

### Decision

Replace MorphLLM with fully local models and replace SQLite + numpy with LanceDB:

- **Embedder**: `BAAI/bge-small-en-v1.5` via `sentence-transformers` (384 dims, runs locally via PyTorch/ONNX, no network dependency at inference time)
- **Reranker**: `cross-encoder/ms-marco-MiniLM-L-6-v2` via `sentence-transformers` (fully local cross-encoder, no network dependency)
- **Vector store**: LanceDB (embedded columnar vector store, no server process required, Apache Arrow-native, persists to local disk at `.grounded-rag/lance/`)

Grounded RAG is entirely self-contained.
No external API calls. No gateway dependency. No new server processes.

### Rationale

- Full self-containment is a hard requirement: Grounded RAG must work in any environment without network access to external services.
- `sentence-transformers` models run via PyTorch or ONNX locally — zero network calls at inference time after initial model download.
- LanceDB is an embedded database (analogous to SQLite for vectors) — no server process, stores to a local directory, portable.
- `BAAI/bge-small-en-v1.5` delivers strong code retrieval quality at 384 dims; smaller dimension reduces index size and query latency compared to 1536 dims.
- `cross-encoder/ms-marco-MiniLM-L-6-v2` provides genuine relevance ranking without any external service.
- First run requires model download (~90 MB embedder, ~80 MB reranker); all subsequent runs are fully offline.

### Consequences

- Embedding dimension changes from 1536 (morph-embedding-v4) to **384** (bge-small-en-v1.5). Changing this invalidates any existing index — dimension is frozen for v1.
- Gateway independence is scoped to inference only. Deployment and skill registration remain subject to ADR-006 (Aegis Drop), which may interact with the external MCP gateway. The gateway is a deployment-time dependency, not a runtime inference dependency.
- LanceDB index persists to `.grounded-rag/lance/` by default; ephemeral (in-memory) mode is the default for CI/test runs. See ADR-010 for schema and layer mapping details.
- Model hot-swap requires a `BehavioralCertificate` only when the replacement model has the **same embedding dimension** (384). A model swap that changes dimension triggers a full index rebuild and requires a constitution amendment — it is not a behavioral swap. Local sentence-transformers models are inspectable; bisimulation-equivalence may be assessed via empirical retrieval quality comparison rather than formal proof.
- The "no external calls" guarantee applies to steady-state inference. First-run model initialization downloads ~170 MB of model weights (embedder ~90 MB, reranker ~80 MB) from HuggingFace Hub. After download, all inference is fully offline. Operators in air-gapped environments must pre-stage model weights manually.
- Python dependency additions: `sentence-transformers`, `lancedb`, `pyarrow`.
- **Migration impact:** Any installation using ADR-005 (MorphLLM, 1536-dim index) cannot migrate forward incrementally. The index must be fully rebuilt from source: old 1536-dim vectors are incompatible with the new 384-dim schema. Migration procedure: delete `.grounded-rag/lance/`, re-run ingest pipeline.
- **Rollback plan:** Reverting to ADR-005 requires: (1) reinstating the external MCP gateway inference path in code, (2) reverting ADR changes, (3) full index rebuild with 1536-dim vectors. Rollback is not incremental — it requires a complete index rebuild. Rollback procedure is an explicit deferral to post-v1.

---

## ADR-010: LanceDB as the v1 Vector Store

- **Status:** Accepted
- **Date:** 2026-03-27
- **Authors:** Skill Architect
- **Related:** ADR-007, ADR-009

### Context

ADR-005 specified "SQLite + numpy" as the vector store.
ADR-009 superseded ADR-005 and introduced LanceDB without a dedicated decision record.
The vector store is a distinct architectural choice from the embedding model and requires its own justification — particularly because ADR-007 reserves L2–L4 layer names, a constraint that must be expressible in whatever store is chosen.

Options considered:

1. SQLite + numpy — ad-hoc, no native vector type, no columnar format, no schema-enforced dimension checks
2. Chroma — embedded, Python-native, opinionated schema with limited Arrow interop
3. FAISS + SQLite — fast ANN, but FAISS is index-only and requires a separate metadata store
4. **LanceDB** — embedded columnar vector store, Apache Arrow-native, no server process, disk-persistent, Python-native

### Decision

Use **LanceDB** as the v1 vector store.

- Storage: `.grounded-rag/lance/` (local disk, git-ignored)
- Format: Apache Arrow columnar (portable binary files)
- Layer mapping: each RGMem layer is a separate LanceDB table (`l0_bm25`, `l1_statements`); L2–L4 tables are declared as reserved (empty, schema-only, `_reserved: true` flag)
- Ephemeral mode: in-memory LanceDB (no disk writes) for stateless or test runs

### Rationale

- Embedded with no server process: fully consistent with the self-containment requirement (ADR-009).
- Apache Arrow-native: schema-typed columns for embedding vectors enforce dimension constraints at ingest — dimension mismatches are rejected at write time, not silently stored.
- LanceDB tables map naturally to RGMem layer names. Reserved layers (L2–L4) are declared as empty tables with `_reserved: true`, satisfying ADR-007's reservation constraint without schema collisions.
- Portability: Arrow files can be exported, versioned, or archived independently of the application.
- Python-native API with no additional daemon process.

### Consequences

- L1 embedding dimension (384) is enforced at the LanceDB schema level on table creation. Mismatched vectors are rejected at ingest, not silently stored. This closes the index-corruption risk identified in ADR-007.
- Reserved layers (L2–L4) are declared as empty tables with `_reserved: true` — populating them requires a constitution amendment (carried forward from ADR-007).
- LanceDB index files (`.grounded-rag/lance/`) must be added to `.gitignore` — they are derived artifacts, not source truth.
- Ephemeral mode (in-memory) is the default for CI/test runs; persistent mode requires explicit opt-in via config.
- Migration from any prior SQLite + numpy prototype index requires a full re-ingest (no format bridge exists).

---

## ADR-011: Constitution Amendment — Runtime Self-Containment as Hard Constraint

- **Status:** Accepted
- **Date:** 2026-03-27
- **Authors:** Skill Architect
- **Amends:** Constitution §Objective Hierarchy

### Context

The Objective Hierarchy in `docs/constitution.md` ranked portability at #7 — the lowest priority.
ADR-009's decision to require zero external runtime dependencies was justified by the project's founding requirement, but it cited portability as the rationale.
This created a procedural gap: portability at #7 could theoretically be overridden by objectives #3–#6 (useful answer quality, replayability, latency, adaptive improvement speed), implying that a sufficiently strong quality or latency argument could justify reintroducing external inference dependencies.
That implication is incorrect and must be closed.

### Decision

Amend `docs/constitution.md §Objective Hierarchy` to add a **Hard Constraint: Runtime Self-Containment** immediately after the priority list:

- Runtime self-containment is a co-equal hard constraint alongside objective #2 (Grounded correctness).
- Grounded RAG must function without any external API calls, network services, or running daemons at inference time.
- This constraint cannot be traded off against any lower-priority objective in the hierarchy.
- Steady-state inference must be fully offline-capable.
- One-time initialization (e.g., model weight download) is permitted but must be documented, bounded, and air-gap-stageable.
- Deployment-time dependencies (Aegis Drop, policy bundle signing) are outside the scope of this constraint.

### Rationale

Self-containment is more precisely a prerequisite for correctness guarantees than a portability preference.
A system that can fail at inference time due to an unavailable external service cannot provide grounded answers reliably — it violates objective #2 at the infrastructure level before any retrieval logic runs.
Framing it as portability understated its importance and left the hierarchy open to misreading.

### Clause Changed

`docs/constitution.md §Objective Hierarchy` — paragraph: "Higher-priority objectives always win over lower-priority objectives."
Added: Hard Constraint section immediately after that paragraph.

### Migration Impact

No migration required.
All current implementations (ADR-009, ADR-010) already satisfy this constraint.
The amendment formalizes an existing design invariant rather than introducing a new operational requirement.

### Rollback Plan

To revert: remove the Hard Constraint section from `docs/constitution.md §Objective Hierarchy` and remove this ADR.
No code or index changes are required — this amendment is documentation-only.

---

## Amendment Log

| Date | ADR | Clause Changed | Reason | Author |
|------|-----|----------------|--------|--------|
| 2026-03-27 | ADR-005 | Entire decision | Self-containment requirement: replace MorphLLM + SQLite/numpy with local sentence-transformers + LanceDB (see ADR-009 for migration impact and rollback plan) | Skill Architect |
| 2026-03-27 | — | New record | ADR-010: LanceDB vector store — extracted from ADR-009 to document layer schema mapping and dimension enforcement separately | Skill Architect |
| 2026-03-27 | Constitution §Objective Hierarchy | Hard Constraint added | Runtime self-containment elevated to co-equal hard constraint with objective #2; closes portability-ranking gap exposed by ADR-009 (see ADR-011) | Skill Architect |
