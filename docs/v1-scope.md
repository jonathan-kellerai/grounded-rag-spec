# Grounded RAG V1 Scope

## Product Identity

Grounded RAG v1 is a repo-scoped answering skill for engineers and maintainers.

It answers questions about a single codebase and its local documentation using
anchored evidence spans and replayable traces.

It is not, in v1:

- a general epistemic operating system
- a federated cognition mesh
- a live model-training platform
- a web-scale strip-mining system
- a cross-tenant memory layer

## First User

The first user is an engineer or maintainer working inside one repo who needs:

- implementation answers
- architecture answers
- doc-grounded explanations
- code-plus-doc synthesis

## First Corpus

The v1 corpus is limited to:

- repo source files
- repo markdown and docs
- ADRs and design docs in-repo
- local config and specification files

V1 explicitly excludes:

- web crawling
- chat logs
- Jira
- Slack
- email
- external enterprise systems
- cross-repo shared memory

## Smallest Falsifiable Loop

The v1 thesis stands or falls on one loop:

1. ingest one repo's code and docs
2. answer engineering questions with direct evidence spans
3. attach replayable traces and citations
4. outperform a simpler span-RAG baseline on usefulness and groundedness
5. survive revocation plus degraded-mode fallback

If that loop does not win, the larger Grounded RAG architecture is not earned.

## Exact Answer Contract

Every answer must return one of:

- `Grounded`: direct evidence supports the answer
- `Partial`: some answer can be given, but important coverage gaps remain
- `Abstain`: evidence is insufficient or unsafe

Every non-abstaining answer must include:

- the answer text
- cited evidence spans
- a coverage state
- an `EpistemicStatus` summary (`conflict_type` and `extension_count` at minimum)
- an `uncertainty_interval` as `[Bel, Pl]` pair
- a snapshot id

The system must abstain when:

- no direct evidence supports the core answer
- likely-relevant material was forbidden by policy
- unresolved contradiction remains on a high-impact question
- the system is in degraded safety mode and cannot answer safely

## V1 Object Model

### Required live-path objects

- `SourceRecord`
- `SourceVersion`
- `EvidenceSpan`
- `RetrievalTrace`
- `AnswerAuditRecord`

### Offline-only derived objects

- `Claim`
- `Entity`
- `Contradiction`

These are explicitly not on the hot path in v1.

## Online / Offline Partition

### Online path

The online path is intentionally narrow:

1. retrieve candidate evidence spans
2. rerank
3. assemble context
4. synthesize answer
5. emit citations and audit trace

### Offline path

The following happen only offline in v1:

- claim extraction
- contradiction consolidation
- benchmark generation
- policy experiments
- compaction
- revocation rebuilds

## Evolution Boundaries

### May evolve in v1

- span selection heuristics
- retrieval depth
- rerank thresholds
- context packing
- abstention thresholds
- source-priority heuristics
- retrieval resolution layer selection (which of the five index
  layers — BM25/token L0, statement-level L1, function-level L2,
  module-level L3, subsystem-cluster L4 — is queried per query
  topology class); layer routing is a heuristic policy and may
  evolve without constitution amendment
- `CognitiveLoadScore` weighting coefficients (the hard ceiling
  of 5 primary EvidenceSpans per AnswerAuditRecord is fixed;
  only the scoring weights are adjustable)

### Must not evolve automatically in v1

- model weights
- public answer contract
- source capability rules
- provenance schema
- benchmark gold cases
- root ontology types
- `EpistemicStatus` conflict taxonomy (Pollock rebutting/undercutting/none)
- BPA frame Θ = {Grounded, Partial, Abstain} and mass assignment formula
- `ConfidenceTier` thresholds (`REASONABLE_SUSPICION` ≥0.4,
  `PREPONDERANCE` ≥0.65 BPA Bel, `BEYOND_REASONABLE_DOUBT` ≥0.85
  BPA Bel with extension_count=0)

## Negative Evidence and Forgetting

V1 must distinguish:

- searched and found nothing
- not searched
- forbidden from searching
- stale evidence

### Coverage state precedence

When more than one coverage state could apply, emit the single
highest-priority state (highest first):

1. `forbidden`
2. `stale`
3. `searched_none`
4. `covered_partial`
5. `covered_direct`
6. `not_searched`

Safety-critical states always dominate informational states. Only one
coverage state is emitted per answer.

V1 must also support these non-active end states:

- `expired`
- `revoked`
- `suppressed`
- `archived`

## Boring Mode

The boring path is mandatory:

- evidence-span retrieval only
- fixed answer template
- no claim usage
- no policy evolution
- no reliance on derived objects

This is the fallback mode whenever higher-order systems are degraded or frozen.

## Decision Rights

V1 assigns explicit roles:

- `Corpus Owner`
- `Skill Architect`
- `Release Authority`
- `Incident Owner`

No autonomous policy promotion or source expansion is allowed without a named
human authority being responsible for it.

## Kill Criteria

The v1 architecture fails if, after the first serious prototype:

- grounded answer usefulness is not at least 15% better than a simpler
  evidence-span baseline

### Required baseline definition

The comparison baseline for the 15% kill criterion is fixed as:
- retrieval: top-k BM25 keyword retrieval over raw source chunks, k=5
- reranking: none
- context assembly: concatenate retrieved chunks in retrieval score order
- synthesis: fixed prompt template with no coverage-state logic
- provenance: none beyond chunk source path
- answer state: not emitted

This baseline must be implemented as part of Track F. Measuring against any
other baseline requires an `ArchitectureDecisionRecord` naming the substitution
and the reason.

- end-to-end latency is more than 2x the simpler baseline without clear trust
  gains
- operator review load exceeds 1 hour per day per active corpus

### Operator review load measurement

Operator review load is the sum of:
- time reviewing offline review queue items
- time responding to circuit breaker events (open → half-open transitions)
- time spent on source admission or revocation decisions

Measurement window: rolling 7-day average, per active corpus.
The kill criterion triggers if the average exceeds 1 hour per calendar day.
Measurement must be logged. Self-reported estimates are not acceptable as
the sole measurement method.

- replay is unreliable
- revocation is unreliable
- boring mode is not sufficient to keep the product usable

## Explicit Deferrals

The following are intentionally deferred:

- federation
- live model apprentices
- runtime reasoning-engine integration
- broad claim-native serving
- multi-tenant shared memory
- portable mycelium
- aggressive external strip-mining
- `BehavioralCertificate` issuance and bisimulation-equivalence
  checking for embedding model hot-swap (deferred to post-v1;
  the LTS behavioral spec must be authored before any
  zero-downtime model swap is attempted)
- full five-layer RGMem index (L2–L4 layers are deferred; v1
  implements L0 BM25 and L1 statement-level embeddings only;
  L2–L4 are reserved layer names that must not be occupied by
  ad-hoc structures)

## Authoring Contract

A developer creating a Grounded RAG skill in v1 must declare exactly:

- scope statement
- source classes
- answer contract
- admission and revocation rules
- retrieval policy baseline
- benchmark seed set
- degraded-mode behavior

### Minimum benchmark seed requirements

A benchmark seed set is only valid if it contains:
- at least 20 total cases
- at least 5 cases whose correct answer state is `Abstain`
- at least 5 cases requiring synthesis across two or more source files
- at least 3 cases testing revocation behavior
- at least 1 case per defined coverage state

A seed set that does not exercise all three answer states is insufficient
and must not be used as the evaluation foundation for a policy promotion.

Everything else is optional and must not be forced into the initial authoring
experience.
