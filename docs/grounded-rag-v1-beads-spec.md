<!-- markdownlint-disable -->
# Grounded RAG V1: Self-Contained Proposal and Beads Ingest Spec

> **Comprehensive proposal packet + `bd create --file` compatible implementation spec**
>
> - **Project:** Grounded RAG
> - **Date:** 2026-03-26
> - **Status:** Proposal (forced scope, self-contained, beads-ingestible)
> - **Spec ID:** `grounded-rag-v1-beads-spec-2026-03-26`
> - **Binding docs:** `docs/constitution.md`, `docs/v1-scope.md`
> - **Ingest command:** `bd create --file docs/grounded-rag-v1-beads-spec.md --validate --spec-id grounded-rag-v1-beads-spec-2026-03-26`
> - **Parser note:** `bd create --file` does not support `--dry-run`; validate on ingest
> - **Spec format:** `bd create --file` compatible (H2 sections below `---`)

---

# Part I: What is Grounded RAG?

### The Problem

Most retrieval-augmented systems for code and docs inherit the wrong first
principles:

- chunks become the default unit of truth
- provenance is weak or cosmetic
- answer contracts are vague
- evaluation is bolted on after the system becomes opaque
- deployment and trust are treated as somebody else's problem
- richer reasoning is attempted before the live serving loop is honest

The result is familiar: a system that can often answer, but cannot reliably
show why it answered that way, cannot safely degrade, and cannot be cleanly
revised when a source is revoked or a retrieval policy changes.

Grounded RAG exists to attack those defaults directly.

### The Solution

Grounded RAG v1 is a repo-scoped, evidence-backed answering skill for engineers
and maintainers.

From the outside it should look small:

- one skill surface
- narrow input/output contract
- minimal operator-visible sprawl

Inside, it may contain:

- source admission and corpus versioning
- evidence span extraction
- retrieval and reranking
- context assembly
- answer synthesis
- replayable provenance traces
- offline benchmark generation
- optional offline claimification and contradiction analysis

The key design move is to keep the live path deliberately narrow while making
the offline and governance story unusually strong.

### The First Serious Cut

Grounded RAG v1 is not trying to prove a full epistemic operating system.
It is trying to prove one smaller and more defensible thesis:

1. one repo's code and docs can be ingested into a versioned corpus
2. engineering questions can be answered from direct `EvidenceSpan` references
3. every non-abstaining answer can carry replayable provenance
4. revocation and degraded-mode fallback can be made real
5. this can still outperform a simpler span-RAG baseline on usefulness and
   groundedness

If that loop fails, the larger architecture is not earned.

### What Grounded RAG Is Not

Grounded RAG v1 is not:

- a web-scale crawler
- a cross-tenant memory service
- a federated cognition mesh
- a live model-training platform
- a general deployment substrate
- a broad claim-native truth engine

Those may remain future research directions, but they are explicitly outside the
kernel of the first real product cut.

### Core Architecture

The v1 architecture is intentionally asymmetric:

- the live serving substrate is `EvidenceSpan`, not `Claim`
- the online loop is narrow, boring, and testable
- claims and contradictions are derived offline layers, not hot-path truth
- provenance is replayable derivation, not just cited references
- retrieval should adapt to question shape, but only under explicit routing
  control
- governance and deployment stay in adjacent systems instead of being silently
  reimplemented inside the runtime

That combination is what makes the proposal both ambitious and constrained.

# Part II: Background on Aegis Drop and Adjacent Systems

### Aegis Drop: What It Is

Aegis Drop is the sister deployment project for portable cognition capsules.
Its dominant identity is not "plugin manager" or "runtime shell." It is a
trusted release and deployment substrate.

Its one-sentence job is:

Turn a portable cognition capsule from a local artifact into a deployable,
attestable, rollbackable, and revocable runtime object.

That matters because a hidden-depth skill is only interesting locally until it
needs trusted packaging, admission control, rollback, and audit.

### Aegis Drop: How It Works

The core Aegis unit is a `ReleaseEnvelope`.

A `ReleaseEnvelope` is not just a tarball or directory. It is an immutable
release object that carries:

- one capsule payload
- one machine-readable `ReleaseManifest`
- one dependency lock
- one compatibility-class declaration
- one attestation set bound to the exact envelope digest

Deployability is decided over an exact trust tuple:

- `ReleaseEnvelope` digest
- embedded `ReleaseManifest`
- embedded dependency lock
- embedded attestation set
- selected `PolicySnapshot`
- selected `EnvironmentProfile`

Aegis Drop is compelling because it forces precision on questions that most
systems answer lazily:

- what exact thing is being shipped
- what exact thing is trusted
- what exact thing was validated
- what exact thing can be rolled back
- what exact thing has been revoked

### Aegis Drop: What Makes It Special

The strongest Aegis ideas for Grounded RAG are:

- explicit deployable unit
- explicit trust unit
- explicit rollback and revocation units
- circuit breakers
- conservative degraded mode
- a portability contract that separates what travels with an artifact from what
  remains environmental state

This is not superficial release hygiene. It is the difference between a clever
local skill and a governed runtime object.

### Why Aegis Drop Matters to Grounded RAG

Grounded RAG is about internal cognition hidden behind a small shell.
Aegis Drop is about giving that shell a trustworthy outer boundary.

Without Aegis Drop, Grounded RAG can stay a local experiment.
With Aegis Drop, Grounded RAG can eventually become a capsule with:

- explicit release boundaries
- policy-gated deployment
- rollback discipline
- revocation semantics
- attested runtime admission

The role split matters:

- Grounded RAG should own answering
- Aegis Drop should own release and deployment trust

That boundary is one of the core architectural decisions in this proposal.

### Sentinel: Why It Is Relevant

Sentinel is the strongest local research-distillation substrate discovered so
far.

Its transferable primitives are:

- a research refinery that turns paper extracts into structured explainers
- a citation lattice that maps concepts to formulas and system components
- reveal surfaces that make dense architecture inspectable

Sentinel matters because it treats research as structured substrate, not just as
a bibliography.

### Truth JBT: Why It Is Relevant

Truth JBT is the strongest local governance and control-plane reference
discovered so far.

Its transferable primitives are:

- governed discovery of skills, agents, hooks, and components
- explicit visibility and enable/disable state
- history, telemetry, and ranking surfaces
- conflict detection and sync semantics

Truth JBT matters because it treats change, visibility, and control state as
first-class governable objects.

# Part III: The Four Research-Grounded Findings

### Finding 1: The Serving Substrate Should Be `EvidenceSpan`, Not `Claim`

#### What It Is

The proposal initially drifted toward claim-native serving.
That was a mistake for v1.

The better first cut is:

- raw sources remain first-class
- `EvidenceSpan` is the canonical live serving object
- `Claim` is a derived, offline epistemic object

#### Why It Is Special

Claims are compressive interpretations.
That makes them powerful for verification and evaluation, but dangerous as the
only live truth substrate. If claim extraction is wrong, the system can freeze
that wrongness into its ontology and lose the qualifiers, ambiguity, and local
context that made the original source useful.

This finding is what keeps Grounded RAG honest. It preserves a path toward richer
claim-native reasoning later without pretending that extraction is already
reliable enough to carry the hot path today.

#### How It Works

In practice, this means:

- source material is versioned directly
- spans are extracted from source versions and remain addressable
- retrieval and reranking operate over evidence spans
- claims, entities, and contradictions are built offline and are never required
  for a v1 answer to work

#### Why It Enhances The Project

This makes the first product simpler to test, easier to replay, easier to
revoke, and more defensible against ontology drift. It also gives later models
or reviewers a much cleaner attack surface: if answers are wrong, the failure is
not hidden behind an unearned claim layer.

### Finding 2: Provenance Must Be A Replayable Derivation Trace

#### What It Is

Loose "citation" language is not enough.
In a multi-step answering system, provenance must identify:

- what was retrieved
- what was reranked
- what context was assembled
- what answer was synthesized
- where unsupported or stale content entered the workflow

#### Why It Is Special

This is one of the most compelling possible differentiators for Grounded RAG.
Many systems can cite sources. Far fewer can replay a specific answer against a
specific snapshot and localize the stage where the answer went wrong.

That turns provenance from a formatting feature into a debugging and trust
feature.

#### How It Works

The design consequence is a stage-aware audit trail built from durable objects
such as:

- `RetrievalTrace`
- `AnswerAuditRecord`
- pinned `PolicySnapshot` identifiers
- explicit evidence references

The trace should be layered:

- minimal metadata on every answer
- deeper replay data available for audit and debugging

#### Why It Enhances The Project

This gives Grounded RAG a much stronger revision loop.
Bad answers can be analyzed in terms of retrieval failure, routing failure,
context-assembly failure, or synthesis failure. Revocation can be traced
forward into affected answers. Policy changes can be replayed against old cases.

### Finding 3: Retrieval Should Be Query-Topology Aware

#### What It Is

Not all questions should enter the same retrieval posture.

Examples:

- local evidence lookup: "Where is auth checked?"
- local explanation: "What does this function return?"
- broader synthesis: "What are the coupling points in this repo?"
- corpus-wide change analysis: "What moved architecturally in the last two
  weeks?"

Treating all of them as one retrieval problem is a structural mistake.

#### Why It Is Special

This finding opens a different path to intelligence.
Instead of immediately betting on live model self-improvement, Grounded RAG can
become more adaptive by routing the query to the right retrieval posture.

That can compound quality without creating an uncontrolled adaptive runtime.

#### How It Works

The safe v1 version is narrow:

- classify questions only into coarse buckets such as `local` and `global`
- default to the local path when uncertain
- never let the classifier bypass the evidence-backed answer contract
- expose routing decisions in the trace instead of hiding them

#### Why It Enhances The Project

This improves fit between question type and retrieval cost.
Local questions get low-latency, tight evidence retrieval.
Broader questions can spend more budget on wider retrieval or aggregation, but
only when justified.

### Finding 4: The Strongest Architecture Is A Two-Plane System

#### What It Is

The strongest synthesis so far is:

- Sentinel contributes the distillation and knowledge-refinery plane
- Truth JBT contributes the governance and control-plane logic
- Aegis Drop contributes the release and deployment boundary
- Grounded RAG itself remains the answering capsule

#### Why It Is Special

This avoids a familiar failure mode:
trying to force ingestion, governance, deployment trust, and answering
into one dense runtime.

Instead, each plane keeps its own job:

- Sentinel metabolizes research and structured knowledge
- Truth JBT governs visibility, state, and control surfaces
- Aegis Drop governs trusted packaging, admission, rollback, and revocation
- Grounded RAG answers from evidence

#### How It Works

The consequence is architectural restraint:

- Grounded RAG should not silently become its own deployment substrate
- Grounded RAG should not try to absorb all governance into the hot path
- Grounded RAG may depend on richer adjacent systems while keeping its public
  surface small

#### Why It Enhances The Project

This makes the system more legible and more composable.
It also means reviewers can critique each boundary separately:

- does the answer path work
- does governance belong where it is
- does deployment trust belong where it is

That is a healthier architecture than a single "smart runtime" that owns
everything.

# Part IV: Forced V1 Decisions

### Product Identity

Grounded RAG v1 is a repo-scoped answering skill for engineers and maintainers.

### First User

The first user is an engineer or maintainer working inside one codebase and
asking questions about implementation, architecture, and local documentation.

### First Corpus

The v1 corpus is limited to:

- source files
- repo docs
- ADRs and design docs
- local config/spec files

It explicitly excludes web crawl, Slack, Jira, email, and multi-tenant memory.

### Canonical Object

The canonical epistemic object in v1 is `EvidenceSpan`.

### Public Answer States

Every answer must be one of:

- `Grounded`
- `Partial`
- `Abstain`

Every non-abstaining answer must include:

- answer text
- cited evidence spans
- coverage state
- `EpistemicStatus` summary (conflict_type, conflict_degree, extension_count)
- `uncertainty_interval` [Bel, Pl] from combined BPA across cited spans
- `confidence_tier` of the answer (tier of the weakest cited span)
- snapshot id

### Online And Offline Split

The online path may only:

1. retrieve evidence spans
2. rerank
3. assemble context
4. synthesize an answer
5. emit citations and a replayable trace

Offline-only in v1:

- claim extraction
- contradiction consolidation
- benchmark generation
- policy experiments
- revocation rebuilds
- compaction

### Boring Mode

The system must always support a degraded path that depends only on:

- evidence-span retrieval
- fixed synthesis template
- no claim usage
- no automatic evolution

### Smallest Falsifiable Loop

The architecture stands or falls on this loop:

1. ingest one repo's code and docs
2. answer engineering questions from direct evidence spans
3. attach replayable traces and citations
4. outperform a simpler span-RAG baseline
5. survive revocation and degraded-mode fallback

### Explicit Deferrals

Not in v1:

- federation
- live model apprentices
- runtime reasoning-engine integration
- broad claim-native serving
- multi-tenant shared memory
- aggressive external strip-mining

# Part V: What Another Model Should Attack

### Product Fit

- Is the v1 loop narrow enough and still meaningful?
- Is the answer contract precise enough?
- Does the product identity stay stable under implementation pressure?

### Object Model

- Is `EvidenceSpan` the right live canonical object?
- Are claims correctly demoted to a derived offline layer?
- Are the durable objects minimal and sufficient?

### Provenance

- Is the derivation model realistic and affordable?
- Is replay strong enough to support debugging and revocation?
- Is there any explainability theater hiding behind the trace?

### Routing

- Is query-topology routing worth its added failure surface?
- Is the classifier constrained enough to avoid becoming a hidden oracle?

### Boundaries

- Is the split between Grounded RAG, Sentinel, Truth JBT, and Aegis Drop clean?
- Are we borrowing real primitives or just strong metaphors?

---

## Grounded RAG V1 - Repo-Scoped Evidence-Backed Answering Capsule

Grounded RAG v1 is a repo-scoped answering skill for one codebase's code and
docs. It serves answers from anchored `EvidenceSpan` objects, not from an
unbounded claim layer. The live path is intentionally narrow: retrieve spans,
rerank, assemble context, synthesize answer, emit citations and replayable
trace. Governance exists to protect answer integrity, not to turn the runtime
into a sprawling epistemic platform.

This epic covers the smallest serious implementation cut that validates the
thesis while preserving the strongest long-range ideas:

- `EvidenceSpan` is the live serving substrate
- provenance is a replayable derivation trace
- retrieval posture depends on query topology
- deployment trust stays outside the hot path, with Aegis Drop as the eventual
  release substrate

**Success metrics:**

- one repo can be ingested and snapshotted deterministically
- engineering questions return `Grounded`, `Partial`, or `Abstain`
- every non-abstaining answer includes cited spans and snapshot id
- replay works from durable records
- revocation removes revoked material from future serving
- boring mode remains usable
- the system beats a simpler span-RAG baseline on usefulness and groundedness

### Priority
1

### Type
epic

### Design
**Product boundary:**
Grounded RAG is an answering capsule, not a deployment substrate and not a
general epistemic OS.

**Kernel objects:**
Required durable objects in v1 are:

- `SourceRecord`
- `SourceVersion`
- `EvidenceSpan`
- `PolicySnapshot`
- `BenchmarkCase`
- `RetrievalTrace`
- `RevocationRecord`
- `AnswerAuditRecord`

**Live path:**
1. admit and snapshot repo-scoped sources
2. build and index `EvidenceSpan` objects
3. retrieve and rerank candidate spans
4. assemble answer context
5. synthesize answer with explicit state
6. emit citations, coverage state, contradiction flag, and snapshot id
7. write replayable audit records

**Offline path:**
- benchmark generation
- policy evaluation
- compaction
- revocation rebuilds
- optional claimification and contradiction experiments

**Non-negotiable v1 rules:**
- no answer without anchored evidence unless abstaining
- no hot-path dependency on claims
- no silent policy mutation without `PolicySnapshot`
- no fail-open if higher-order systems degrade

### Acceptance Criteria
- [ ] All blocking decision and feature issues are complete
- [ ] One repo corpus can be ingested and snapshotted deterministically
- [ ] Questions about code and docs return `Grounded`, `Partial`, or `Abstain`
- [ ] Every non-abstaining answer includes cited spans and snapshot id
- [ ] Replay works from durable records
- [ ] Revocation removes revoked material from future serving
- [ ] Boring mode remains usable
- [ ] The system beats a simpler span-RAG baseline on usefulness and groundedness
      or the epic is judged failed

### Labels
epic, grounded-rag, v1, answering, evidence

---

## Grounded RAG Decision - EvidenceSpan Is The Live Serving Substrate

Grounded RAG v1 will serve from `EvidenceSpan`, not `Claim`.
Claims remain useful, but only as derived offline objects for evaluation,
compression, or later research lanes. This decision exists to prevent the
runtime from freezing claim-extraction mistakes into the primary serving
ontology before the project has earned that complexity.

### Priority
0

### Type
decision

### Design
**Decision:**
`EvidenceSpan` is the canonical live object in v1.

**Rationale:**
- source material stays first-class
- evidence spans preserve local context and qualifiers
- claims are lossy interpretations and are therefore not trusted as the only
  live truth substrate

**Implications:**
- retrieval, reranking, and answer synthesis operate on spans
- boring mode depends only on source versions plus evidence spans
- claim extraction may exist offline, but cannot be a precondition for serving
- benchmark gold cases must reference raw evidence spans directly

### Acceptance Criteria
- [ ] This spec defines `EvidenceSpan` as the v1 canonical object
- [ ] No live-path feature requires claims to answer
- [ ] Claim extraction is explicitly offline-only and feature-gated
- [ ] Boring mode is fully defined without claim dependency

### Labels
decision, grounded-rag, ontology, evidence

### Dependencies
blocks:Grounded RAG V1 - Repo-Scoped Evidence-Backed Answering Capsule

---

## Grounded RAG Decision - Provenance Is A Replayable Derivation Trace

Grounded RAG v1 will treat provenance as a replayable, stage-aware derivation
trace rather than as a decorative citation list. The goal is not only to know
which sources were cited, but to know how an answer was assembled and where it
went wrong when it fails.

### Priority
0

### Type
decision

### Design
**Decision:**
Every served answer must be bound to a replayable trace with a pinned snapshot.

**Minimum required provenance layers:**
- retrieved candidate spans
- reranked spans
- assembled answer context
- final answer state
- snapshot id and policy version

**Failure-localization intent:**
The trace must make it possible to distinguish at least:
- retrieval failure
- context assembly failure
- synthesis failure
- stale source failure

**Implications:**
- `RetrievalTrace` and `AnswerAuditRecord` are mandatory objects
- every non-abstaining answer must expose cited spans and snapshot id
- revocation and replay depend on durable trace discipline

### Acceptance Criteria
- [ ] This spec defines `RetrievalTrace` and `AnswerAuditRecord` as required
      v1 durable objects
- [ ] Every live-path feature depends on snapshot-pinned records
- [ ] Replay and fault-localization requirements are explicit in this spec
- [ ] No feature in this spec treats provenance as citations-only decoration

### Labels
decision, grounded-rag, provenance, replay

### Dependencies
blocks:Grounded RAG V1 - Repo-Scoped Evidence-Backed Answering Capsule

---

## Grounded RAG Decision - Retrieval Is Query-Topology Aware

Grounded RAG will not treat every question as the same retrieval problem.
At minimum, v1 must distinguish between narrow local evidence lookup and broader
synthesis-style questions, even if the first routing taxonomy remains simple.

### Priority
1

### Type
decision

### Design
**Decision:**
Retrieval posture is allowed to vary by query topology.

**Safe v1 taxonomy:**
- `local`
- `global`

**Safety rules:**
- routing decisions must be visible in the trace
- low-confidence routing falls back to the local path
- routing may not bypass the evidence-backed answer contract
- the topology classifier is a heuristic aid, not a hidden oracle

**Implications:**
- routing is explicit work, not an accidental side effect
- benchmarks must exercise local and global cases separately
- the global path is allowed to cost more, but only when justified

### Acceptance Criteria
- [ ] This spec defines a coarse local/global query-topology split
- [ ] Low-confidence routing fallback is explicit
- [ ] Routing decisions are required to be recorded in the trace
- [ ] No feature in this spec allows routing to weaken evidence requirements

### Labels
decision, grounded-rag, retrieval, routing

### Dependencies
blocks:Grounded RAG V1 - Repo-Scoped Evidence-Backed Answering Capsule

---

## Grounded RAG Decision - Two-Plane Architecture With Aegis Drop Deployment Boundary

Grounded RAG will remain an answering capsule and will not absorb deployment trust
or all governance responsibilities into the live runtime. Sentinel-like
distillation, policy-gated governance, and Aegis-Drop-style deployment trust
are adjacent planes, not excuses to make the hot path heavier.

### Priority
1

### Type
decision

### Design
**Decision:**
Grounded RAG stays focused on answering; deployment trust is externalized to
Aegis Drop.

**Boundary split:**
- Grounded RAG owns answering from evidence
- Sentinel contributes research-distillation patterns
- Truth JBT contributes governance/control-plane patterns
- Aegis Drop owns release envelope, admission, rollback, and revocation for
  deployed capsules

**Implications:**
- Grounded RAG does not become its own deployment substrate
- governance ideas may inform durable objects and control surfaces without
  bloating the live path
- release packaging, attestation, and deploy-time admission are sidecar work,
  not hot-path work

### Acceptance Criteria
- [ ] This spec keeps deployment trust outside the live Grounded RAG path
- [ ] Aegis Drop is described as the eventual release/deployment substrate,
      not as a Grounded RAG internal module
- [ ] Live-path issues stay focused on answering concerns
- [ ] A sidecar packaging boundary issue exists instead of hidden deployment
      assumptions

### Labels
decision, grounded-rag, architecture, aegis-drop

### Dependencies
blocks:Grounded RAG V1 - Repo-Scoped Evidence-Backed Answering Capsule

---

## Grounded RAG Track A - Source Admission And Corpus Snapshot Pipeline

Build the repo-scoped source admission and versioning pipeline that turns local
code and docs into controlled corpus state. This track is responsible for
declaring what enters the system, what is versioned, and what may later be
revoked.

### Priority
0

### Type
feature

### Design
**Scope:**
Admit only the v1 corpus classes:
- source files
- repo markdown/docs
- ADRs/design docs
- local config/spec files

**Core objects:**
- `SourceRecord`
- `SourceVersion`

**Required behavior:**
1. enforce source-class policy at admission time
2. snapshot source versions against repo state
3. retain enough metadata for later replay and revocation
4. reject forbidden source classes rather than silently indexing them

**Versioning requirements:**
- each `SourceVersion` must bind to path, content digest, and corpus snapshot
- snapshotting must be deterministic for the same repo state

**Why this matters:**
Without a clean corpus admission layer, replay and revocation become theater.

### Acceptance Criteria
- [ ] Only allowed v1 source classes are admitted
- [ ] Each admitted source produces stable `SourceRecord` and `SourceVersion`
      data
- [ ] Repo snapshots are reproducible for the same repo state
- [ ] Forbidden source classes are rejected explicitly
- [ ] Source metadata is sufficient to support later evidence-span extraction,
      replay, and revocation

### Labels
backend, grounded-rag, corpus, ingestion, track-a

### Dependencies
blocks:Grounded RAG V1 - Repo-Scoped Evidence-Backed Answering Capsule, discovered-from:Grounded RAG Decision - EvidenceSpan Is The Live Serving Substrate, discovered-from:Grounded RAG Decision - Two-Plane Architecture With Aegis Drop Deployment Boundary

---

## Grounded RAG Track B - EvidenceSpan Extraction, Indexing, And Retrieval

Build the `EvidenceSpan` layer and retrieval substrate. This is the heart of
the serving model: source versions become anchored spans, spans become indexed,
and retrieval operates over those spans rather than over derived claims.

### Priority
0

### Type
feature

### Design
**Core objects:**
- `EvidenceSpan`

**Required behavior:**
1. extract code-aware and doc-aware spans from `SourceVersion`
2. preserve path and position anchors
3. attach provenance back to the exact source version
4. build snapshot-specific retrieval indexes
5. retrieve candidate spans for answer generation

**Retrieval substrate:**
- use the existing concept framing of hidden embedder/reranker roles
- keep retrieval index aligned with corpus snapshots
- make rebuilds deterministic and revocation-aware

**Guardrails from Finding 1:**
- claims are not indexed as the primary serving substrate
- raw source -> source version -> evidence span remains the canonical lineage

**Span identity and deduplication:**

Every `EvidenceSpan` has a canonical identifier:

**EvidenceSpan identity (bitemporal):**

  span_id = hash(content_hash + ":" + valid_start_commit + ":" + tx_start)

Every `EvidenceSpan` carries a bitemporal identity tuple:
  (content_hash, valid_start_commit, valid_end_commit, tx_start, tx_end)

- `valid_start_commit` / `valid_end_commit`: git commit SHAs bounding
  the period when this content was true in the source repo (valid time)
- `tx_start` / `tx_end`: timestamps bounding when Grounded RAG had this
  span in its active index (transaction time); `tx_end` is null while active
- `content_hash`: SHA-256 of the raw span bytes

This replaces the previous `(source_version_id, byte_start, byte_end)` tuple.
The byte-range is retained as `byte_start` / `byte_end` fields for position
anchoring but is no longer the primary identity key.

**Point-in-time retrieval:**
Retrieval accepts an optional `as_of_commit` parameter.
When provided, the index filters to spans where:
  valid_start_commit <= as_of_commit < valid_end_commit
  AND tx_end IS NULL (or tx_end covers the query time)
This enables VersionRAG-style time-travel queries without full re-indexing.
Selective re-indexing: only spans whose `valid_end_commit` equals the new
HEAD commit need updating on corpus refresh (expected 10-15% churn).

**Full EvidenceSpan schema (v1):**

| Field                  | Type                        | Required | Notes                                              |
|------------------------|-----------------------------|----------|----------------------------------------------------|
| `span_id`              | string                      | yes      | hash(content_hash:valid_start_commit:tx_start)     |
| `content_hash`         | string                      | yes      | SHA-256 of raw span bytes                          |
| `source_ref`           | string                      | yes      | path + source_record_id                            |
| `valid_start_commit`   | string                      | yes      | git SHA — content valid from                       |
| `valid_end_commit`     | string (nullable)           | yes      | git SHA — content valid until; null if current     |
| `tx_start`             | timestamp                   | yes      | when Grounded RAG indexed this span                  |
| `tx_end`               | timestamp (nullable)        | yes      | when span was removed from index; null if active   |
| `chunk_algo`           | string                      | yes      | chunking algorithm identifier + version            |
| `embedding_vector_id`  | string                      | yes      | reference into vector store                        |
| `rerank_score`         | float (nullable)            | no       | populated during retrieval                         |
| `assembly_position`    | int (nullable)              | no       | position in assembled context window               |
| `byte_start`           | int                         | yes      | byte offset in source version                      |
| `byte_end`             | int                         | yes      | byte offset end in source version                  |
| `bpa_vector`           | dict[str, float]            | yes      | keys: "Grounded", "Partial", "Abstain", "Theta"    |
| `uncertainty_interval` | tuple[float, float]         | yes      | [Bel, Pl] after BPA normalization                  |
| `confidence_tier`      | enum                        | yes      | REASONABLE_SUSPICION, PREPONDERANCE, or BRD        |
| `epistemic_status`     | EpistemicStatus             | yes      | see schema below                                   |
| `provenance_ledger`    | ProvenanceLedger            | yes      | see schema below                                   |

**BPA vector computation:**
Given cosine similarity `sim` (0–1) and rerank score `rel` (0–1):
  m({Grounded}) = sim * rel
  m({Partial})  = sim * (1 - rel) + (1 - sim) * rel
  m(Θ)          = (1 - sim) * (1 - rel)   [ignorance mass]

BPA vectors from multiple spans are combined using Dempster's rule.
When conflict mass K > 0.5, Yager normalization is applied and the
`AUTOIMMUNE_FAILURE` circuit breaker is evaluated for the source.

**ConfidenceTier thresholds:**
  REASONABLE_SUSPICION: sim >= 0.4
  PREPONDERANCE:        BPA Bel >= 0.65
  BEYOND_REASONABLE_DOUBT (BRD): BPA Bel >= 0.85 AND extension_count == 0

**EpistemicStatus schema:**

| Field                | Type                                    | Notes                                              |
|----------------------|-----------------------------------------|----------------------------------------------------|
| `conflict_type`      | "rebutting" \| "undercutting" \| "none" | per Pollock 1987 defeasible reasoning taxonomy     |
| `conflict_degree`    | float [0, 1]                            | 0 = no conflict, 1 = maximal conflict              |
| `extension_count`    | int                                     | >1 = irresolvable under Dung preferred semantics   |
| `accepted_span_ids`  | list[SpanId]                            | spans in the grounded extension                    |
| `defeated_span_ids`  | list[SpanId]                            | spans defeated in all preferred extensions         |
| `contested_span_ids` | list[SpanId]                            | spans not in all preferred extensions              |

**ProvenanceLedger schema:**

A `ProvenanceLedger` is a hash-linked list of custody steps. Each step
is content-addressed: the hash of step N includes the hash of step N-1.

| Step | Field captured                              | Hash input                        |
|------|---------------------------------------------|-----------------------------------|
| 1    | `source_hash` (SHA-256 of raw document)     | source bytes                      |
| 2    | `chunk_algo` + byte range                   | step1_hash + algo_id + byte_range |
| 3    | `embedding_model_id` + `vector_id`          | step2_hash + model_id + vector_id |
| 4    | `rerank_score` + `rerank_model_id`          | step3_hash + score + model_id     |
| 5    | `assembly_position` + `assembly_timestamp`  | step4_hash + position + timestamp |

The final ledger hash is stored as `ledger_hash` on the span.
Any modification to any field in the chain invalidates `ledger_hash`,
making tampering detectable without a separate signature scheme.

Before admission to the retrieval index, any existing span from the same
bitemporal identity bucket (same `content_hash`, overlapping valid-time window)
is checked. If a span with the same `content_hash` and overlapping
`[valid_start_commit, valid_end_commit)` exists, the wider time window is
retained. Byte-range overlap within the same `content_hash` retains the wider span.

Cross-source deduplication is not performed — two sources may legitimately
contain identical passages and both must be indexable.

Discarded span IDs must be logged in the corpus build record.

### Acceptance Criteria
- [ ] `EvidenceSpan` schema preserves source anchors and snapshot lineage
- [ ] Spans can be rebuilt deterministically from the same source snapshot
- [ ] Candidate retrieval returns anchored evidence spans, not opaque chunks only
- [ ] Indexes are tied to corpus snapshots and can be rebuilt after revocation
- [ ] No hot-path dependency on claim extraction exists

**Multi-resolution index architecture:**

The retrieval index is structured as five named layers. In v1, only L0 and L1
are active. L2–L4 are reserved and must not be populated by ad-hoc structures.

| Layer | Name       | Granularity                                              | Status in v1 |
|-------|------------|----------------------------------------------------------|--------------|
| L0    | token      | BM25 over raw tokens                                     | active       |
| L1    | statement  | statement-level embeddings (BAAI/bge-small-en-v1.5 via sentence-transformers, 384 dims)  | active       |
| L2    | function   | function/procedure summaries                             | reserved     |
| L3    | module     | module-level summaries                                   | reserved     |
| L4    | subsystem  | subsystem cluster abstractions                           | reserved     |

Query routing selects layers:
- `local` topology: L0 + L1 (tight, low-latency)
- `global` topology: L0 + L1 + L2 (when L2 is populated; falls back to
  L0 + L1 if L2 not yet built)

The layer selection is a retrieval heuristic policy and may evolve per
the evolution rules in `docs/v1-scope.md` without a constitution amendment.

**Source Tolerance Gate (immunological pattern):**

Every new document source admitted for the first time undergoes a
three-phase tolerance check before receiving full trust weight:

Phase 1 — Innate check (BM25 schema overlap):
  Compute BM25 similarity between new source and the top-20 known-good
  source documents. If similarity < 0.1, flag for manual Corpus Owner review
  before proceeding.

Phase 2 — Autoreactive check (semantic collision detection):
  Embed a random 10% sample of new source spans and check for high-similarity
  contradiction candidates in the existing index (cosine > 0.85 AND
  EpistemicStatus.conflict_type != "none" on matched existing spans).
  If > 5% of sampled spans trigger this check, the source is flagged
  `AUTOREACTIVE` and the `AUTOIMMUNE_FAILURE` circuit breaker fires
  (new source admission breaker → open for this source class).

Phase 3 — Burn-in period:
  Sources that pass phases 1 and 2 receive a reduced trust weight multiplier
  of 0.7 applied to their BPA `m({Grounded})` mass for the first 10 queries
  that cite them. After 10 queries, full weight is restored automatically.
  The burn-in counter is stored on `SourceRecord`.

### Labels
backend, grounded-rag, retrieval, evidence, track-b

### Dependencies
blocks:Grounded RAG V1 - Repo-Scoped Evidence-Backed Answering Capsule, depends-on:Grounded RAG Track A - Source Admission And Corpus Snapshot Pipeline, discovered-from:Grounded RAG Decision - EvidenceSpan Is The Live Serving Substrate

---

## Grounded RAG Track C - Narrow Online Answering Loop And Answer Contract

Implement the deliberately boring live path: retrieve candidate spans, rerank,
assemble answer context, synthesize a response, and emit one of the three
allowed public answer states.

### Priority
0

### Type
feature

### Design
**Public answer states:**
- `Grounded`
- `Partial`
- `Abstain`

**Required output for non-abstaining answers:**
- answer text
- cited evidence spans
- coverage state
- `EpistemicStatus` summary (conflict_type, conflict_degree, extension_count)
- `uncertainty_interval` [Bel, Pl] from combined BPA across cited spans
- `confidence_tier` of the answer (tier of the weakest cited span)
- snapshot id

**Live path:**
1. retrieve candidate evidence spans
2. apply Source Tolerance Gate weights to retrieved span scores
3. rerank using cross-encoder/ms-marco-MiniLM-L-6-v2 (sentence-transformers, fully local)
4. compute BPA vectors for top-k reranked spans
5. compute EpistemicStatus by running Dung preferred semantics over
   conflicting span pairs (detected by high cosine + conflicting content)
6. run MDL-optimal greedy span selection:
   maximize I(E;Q) / token_cost(E); stop when marginal gain < 1 bit/token;
   hard ceiling: max 5 primary EvidenceSpans (CognitiveLoadScore budget)
7. assemble context from selected spans
8. synthesize answer text
9. combine BPA vectors using Dempster's rule (Yager normalization if K > 0.5)
10. determine ConfidenceTier from combined BPA Bel score
11. emit answer state, citations, EpistemicStatus, uncertainty_interval,
    and confidence_tier

**CognitiveLoadScore:**
  CLS = sum(span_weight_i * complexity_i) for all cited spans
  where complexity is a [1–3] integer: 1=direct quote, 2=single-hop
  synthesis, 3=cross-file synthesis
  Hard ceiling: at most 5 primary EvidenceSpans in any AnswerAuditRecord.
  When the MDL selector would exceed 5 spans, it must re-chunk at higher
  granularity (escalate to L2 if available) rather than truncate.
  Truncation without re-chunking is non-conformant.

**Abstention rules:**
- no direct evidence supports the core answer
- likely-relevant material is forbidden
- unresolved contradiction remains on a high-impact question
- degraded mode cannot answer safely

**Boring-mode compatibility:**
This track must function under a fixed answer template with no claim dependency.

### Acceptance Criteria
- [ ] The service returns exactly `Grounded`, `Partial`, or `Abstain`
- [ ] Every non-abstaining answer includes cited spans and snapshot id
- [ ] Abstention triggers are explicit and testable
- [ ] The hot path requires only retrieval, reranking, context assembly, and
      synthesis
- [ ] A boring-mode template path exists and remains usable

### Labels
backend, grounded-rag, answering, contract, track-c

### Dependencies
blocks:Grounded RAG V1 - Repo-Scoped Evidence-Backed Answering Capsule, depends-on:Grounded RAG Track B - EvidenceSpan Extraction, Indexing, And Retrieval, discovered-from:Grounded RAG Decision - EvidenceSpan Is The Live Serving Substrate, discovered-from:Grounded RAG Decision - Provenance Is A Replayable Derivation Trace

---

## Grounded RAG Track D - Replayable Provenance, Audit Records, And Reveal Surface

Build the stage-aware provenance layer and the first reveal surface.
This is where Grounded RAG becomes inspectable instead of merely plausible.

### Priority
1

### Type
feature

### Design
**Required durable objects:**
- `RetrievalTrace`
- `AnswerAuditRecord`

**Minimum `AnswerAuditRecord` schema:**

| Field                  | Required | Notes                                    |
|------------------------|----------|------------------------------------------|
| `record_id`            | yes      | unique identifier                        |
| `answer_state`         | yes      | `Grounded`, `Partial`, or `Abstain`      |
| `snapshot_id`          | yes      | `PolicySnapshot` identifier              |
| `retrieval_trace_id`   | yes      | FK to `RetrievalTrace`                   |
| `span_ids_cited`       | yes      | ordered list                             |
| `coverage_state`       | yes      | single emitted state                     |
| `epistemic_status`     | yes      | EpistemicStatus object (full)            |
| `uncertainty_interval` | yes      | [Bel, Pl] tuple                          |
| `confidence_tier`      | yes      | tier of weakest cited span               |
| `cognitive_load_score` | yes      | CLS value; must be <= 5 primary spans    |
| `topology_route_used`  | yes      | `local`, `global`, or `unclassified`     |
| `topology_classified`  | yes      | false if fallback was used               |
| `user_signal`          | yes      | `accepted`, `rejected`, or `unchecked`   |
| `created_at`           | yes      |                                          |
| `signal_recorded_at`   | no       | null until signal received               |
| `bpa_conflict_mass`    | yes      | K value from Dempster combination; if > 0.5, Yager normalization was applied |
| `ledger_hashes`        | yes      | list of ProvenanceLedger final hashes for each cited span |

`user_signal` defaults to `unchecked`. A `Grounded` answer with `rejected`
signal must generate an offline review queue item in the same write
transaction.

**Trace requirements:**
- pin the corpus snapshot and policy snapshot used
- record candidate retrieval and final cited spans
- record routing decision and answer state
- make enough data durable to support replay and failure localization

**Reveal surface:**
Expose a minimal "opened doll" view for operators and reviewers:
- what sources were used
- what spans were cited
- what coverage state was emitted
- what routing posture was used
- what snapshot id the answer belongs to

**Cost control:**
The trace must be layered:
- minimal always-on answer metadata
- deeper audit detail available without bloating every UI path

**Stub trace compatibility (pre-Track-E):**

Track E (Priority 2) will not be complete when Track D is first implemented.
Before Track E integration, `RetrievalTrace` records must set:
- `topology_route_used`: `unclassified`
- `topology_classified`: false

This is not a valid production state — it is an explicit stub signaling the
routing layer was not yet active.

Track E acceptance criteria must include a migration step that re-labels
existing `unclassified` records where deterministic re-classification is
possible, and flags the remainder as permanently `unclassified` where it
is not.

### Acceptance Criteria
- [ ] Every served answer writes a `RetrievalTrace` and `AnswerAuditRecord`
- [ ] Replay can recover the exact snapshot and cited evidence used
- [ ] Trace data distinguishes at least retrieval, routing, and synthesis stages
- [ ] A minimal reveal surface exposes cited spans, routing posture, answer
      state, and snapshot id
- [ ] Trace design remains compatible with later revocation impact analysis

### Labels
backend, grounded-rag, provenance, replay, reveal, track-d

### Dependencies
blocks:Grounded RAG V1 - Repo-Scoped Evidence-Backed Answering Capsule, depends-on:Grounded RAG Track C - Narrow Online Answering Loop And Answer Contract, discovered-from:Grounded RAG Decision - Provenance Is A Replayable Derivation Trace

---

## Grounded RAG Track E - Query Topology Routing With Safe Fallback

Add explicit query-topology routing to distinguish local evidence lookup from
broader synthesis-style questions. This track must improve retrieval posture
without turning the classifier into a hidden oracle.

### Priority
2

### Type
feature

### Design
**Initial taxonomy:**
- `local`
- `global`

**Local path characteristics:**
- tighter candidate retrieval
- lower latency target
- narrow context assembly

**Global path characteristics:**
- broader retrieval budget
- higher synthesis allowance
- still evidence-backed, not free-form speculation

**Safety requirements:**
- low-confidence classifier output falls back to `local`
- routing decision is visible in the trace
- routing cannot bypass evidence requirements
- if the classifier is disabled, the product still functions

### Acceptance Criteria
- [ ] Routing taxonomy is limited and explicit
- [ ] Low-confidence routing falls back to the local path
- [ ] Routing decisions are recorded in the audit trace
- [ ] The system remains functional if topology routing is disabled
- [ ] Benchmarks can compare local vs global retrieval behavior separately

### Labels
backend, grounded-rag, routing, retrieval, track-e

### Dependencies
blocks:Grounded RAG V1 - Repo-Scoped Evidence-Backed Answering Capsule, depends-on:Grounded RAG Track C - Narrow Online Answering Loop And Answer Contract, discovered-from:Grounded RAG Decision - Retrieval Is Query-Topology Aware

---

## Grounded RAG Track F - Benchmark Harness And Policy Snapshot Evaluation

Build the benchmark and evaluation layer that decides whether the architecture
is actually winning. This track must ground policy changes in replayable cases
and protect the project from self-congratulatory benchmark drift.

### Priority
1

### Type
feature

### Design
**Required durable objects:**
- `BenchmarkCase`
- `PolicySnapshot`

**Benchmark scope:**
The first benchmark suite must be repo-local and answer-centric, including:
- code symbol retrieval
- cross-file synthesis
- citation fidelity
- contradiction handling where applicable
- abstention correctness
- grounded answer usefulness

**Policy evaluation:**
- run candidate retrieval/assembly policies against fixed benchmark cases
- pin benchmark version into `PolicySnapshot`
- no gold-case mutation on the hot path

**Anti-contamination rules:**
- benchmark cases must not silently derive from the same signals used to grade
  current production improvements
- gold cases are versioned and stable

**Contamination definition:**

A gold case is contaminated if its expected answer was generated using:
- the `EvidenceSpan` retrieval index being evaluated
- the `RetrievalTrace` outputs of the system being evaluated
- the production synthesis prompts in the candidate `PolicySnapshot`
- any model fine-tuned or prompted using those outputs

A gold case is clean if authored by a human given only raw source files, OR
by a model given only raw source files with no access to the retrieval index,
traces, or production prompts.

Gold cases must include a `provenance` field declaring authoring method.
Cases without declared provenance are treated as contaminated.

### Acceptance Criteria
- [ ] Benchmark cases exist for repo-local engineering questions
- [ ] A simpler span-RAG baseline is included for comparison
- [ ] `PolicySnapshot` binds policy versions to benchmark versions
- [ ] Gold cases are durable and protected from automatic mutation
- [ ] Evaluation can compare groundedness, usefulness, and abstention behavior

### Labels
backend, grounded-rag, evals, policy, benchmarks, track-f

### Dependencies
blocks:Grounded RAG V1 - Repo-Scoped Evidence-Backed Answering Capsule, depends-on:Grounded RAG Track C - Narrow Online Answering Loop And Answer Contract, depends-on:Grounded RAG Track D - Replayable Provenance, Audit Records, And Reveal Surface, discovered-from:Grounded RAG Decision - Provenance Is A Replayable Derivation Trace, discovered-from:Grounded RAG Decision - Retrieval Is Query-Topology Aware

---

## Grounded RAG Track G - Revocation, Circuit Breakers, Coverage States, And Boring Mode

Implement the protective mechanics that keep Grounded RAG honest under failure:
revocation, negative evidence states, circuit breakers, and the boring fallback
path. This is the difference between a system that looks rigorous and one that
actually fails safely.

### Priority
0

### Type
feature

### Design
**Required durable object:**
- `RevocationRecord`

**Coverage states:**
- `covered_direct`
- `covered_partial`
- `searched_none`
- `not_searched`
- `forbidden`
- `stale`

**Required controls:**
- new source admission breaker
- durable write breaker
- policy promotion breaker
- derived-object generation breaker
- answering-outside-boring-mode breaker

**Trigger conditions and recovery authority:**

| Breaker                        | closed → open trigger                             | Recovery authority  |
|--------------------------------|---------------------------------------------------|---------------------|
| New source admission           | Corpus Owner stop order OR error rate > 10%/1hr   | Incident Owner      |
| Durable writes                 | Write failure > 5%/5min OR quota exceeded         | Incident Owner      |
| Policy promotion               | Release Authority stop order OR benchmark regress | Release Authority   |
| Derived-object generation      | Offline job failure > 25%/1hr                     | Incident Owner      |
| Answering outside boring mode  | Incident Owner stop order                         | Incident Owner      |
| AUTOIMMUNE_FAILURE             | Source autoreactive check triggers on > 5% of sampled spans for a new source class; fires the new source admission breaker for that source class only; other classes unaffected | Incident Owner |

Half-open → closed for all breakers requires explicit `Release Authority`
approval. All transitions are written to the durable breaker log.

**AUTOIMMUNE_FAILURE isolation rule:**
The `AUTOIMMUNE_FAILURE` breaker fires per source class, not globally.
A new Git repo admitted alongside an existing one that triggers the
autoreactive check must not block admission of the existing source class.
The `SourceRecord` for the flagged source must carry `trust_status:
"autoreactive_flagged"` with the triggering sample statistics attached.

**Revocation behavior:**

- revoked material becomes unavailable for future serving
- downstream retrieval indexes can be rebuilt
- replay retains only minimal tombstone context necessary for audit

**Boring mode:**
- evidence-span retrieval only
- fixed synthesis template
- no claim usage
- no policy evolution

### Acceptance Criteria
- [ ] All required coverage states are represented explicitly
- [ ] Independent circuit breakers exist for the required safety boundaries
- [ ] Revoked material is excluded from future serving
- [ ] Revocation records support rebuild and audit workflows
- [ ] Boring mode works without claims or adaptive policy logic
- [ ] The system fails closed into boring mode rather than failing open

### Labels
backend, grounded-rag, safety, revocation, boring-mode, track-g

### Dependencies
blocks:Grounded RAG V1 - Repo-Scoped Evidence-Backed Answering Capsule, depends-on:Grounded RAG Track A - Source Admission And Corpus Snapshot Pipeline, depends-on:Grounded RAG Track C - Narrow Online Answering Loop And Answer Contract, depends-on:Grounded RAG Track D - Replayable Provenance, Audit Records, And Reveal Surface

---

## Grounded RAG Track H - Aegis Drop Release Boundary For Grounded RAG Capsules

Define the eventual Aegis Drop release boundary for Grounded RAG so the skill can
leave local development as a governed runtime object without dragging
deployment-trust concerns into the hot path. This is a sidecar packaging and
interface track, not a prerequisite for proving the answering thesis.

### Priority
3

### Type
task

### Design
**Goal:**
Specify how a Grounded RAG capsule would map into an Aegis Drop
`ReleaseEnvelope`.

**BehavioralCertificate (deferred post-v1 interface specification):**

A `BehavioralCertificate` is an LTS-based behavioral spec encoding the
observable contract of a Grounded RAG skill deployment as a Labeled
Transition System. Two deployments holding the same certificate are
bisimulation-equivalent and may be hot-swapped without observable
behavior change.

This is relevant to Grounded RAG because the embedding model (bge-small-en-v1.5 via sentence-transformers)
may be replaced in future. A hot-swap is only safe if the new model's
observable behavior (retrieval ordering, span scoring distribution) is
bisimulation-equivalent to the old model under the certificate.

Track H must include in its required outputs:
- a stub `BehavioralCertificate` schema definition (structure only, not
  a live issued certificate)
- a mapping of which Grounded RAG observable transitions would be captured
  (query → retrieval output distribution, rerank → assembly order)
- a note that actual certificate issuance and bisimulation checking are
  deferred to post-v1 and require Aegis Drop integration

A live `BehavioralCertificate` must NOT be issued in v1.
Attempting to swap embedding models without a certificate is non-conformant
post-v1. In v1, model changes require a full `ArchitectureDecisionRecord`
and are not covered by a hot-swap protocol.

**Required outputs:**
- declared capability surface for the answering capsule
- release-manifest boundary for prompts, policies, and runtime expectations
- portability contract for what travels with the artifact vs what stays
  environmental
- rollback and revocation touchpoints between Grounded RAG and Aegis Drop
- stub `BehavioralCertificate` schema (structure only; no live issuance)

**Boundary rule:**
This track must not move deployment admission logic into the live Grounded RAG
runtime. It exists to keep the boundary clean, not to widen the kernel.

### Acceptance Criteria
- [ ] A Grounded RAG-to-Aegis mapping exists for payload, manifest, and policy
      boundary
- [ ] The capability surface is explicit enough for future release admission
- [ ] What travels with the capsule vs what remains environmental state is
      explicit
- [ ] Rollback and revocation responsibilities are split cleanly between
      Grounded RAG and Aegis Drop

### Labels
architecture, grounded-rag, aegis-drop, packaging, track-h

### Dependencies
depends-on:Grounded RAG Track G - Revocation, Circuit Breakers, Coverage States, And Boring Mode, discovered-from:Grounded RAG Decision - Two-Plane Architecture With Aegis Drop Deployment Boundary

