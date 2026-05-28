# Grounded RAG Self-Contained Proposal

## Status

This document is the self-contained proposal packet for Grounded RAG.

It is written so another strong model or reviewer can understand:

- what Grounded RAG is trying to become
- what has already been forced into scope
- what sister systems matter
- what recent research findings materially changed the design
- what is proposed for v1
- what should be attacked, revised, or rejected

This document is not a constitution. The binding rules remain in:

- `docs/constitution.md`
- `docs/v1-scope.md`

This document explains the proposal around those rules.

## Executive Summary

Grounded RAG is a repo-scoped answering skill that hides a retrieval stack behind a
small skill shell. The original concept was "a single skill containing an
entire RAG pipeline plus two small language model roles: embedder and
reranker." That core idea remains, but the proposal has now been tightened by
two constraints:

1. v1 must be a narrow, falsifiable engineering product, not a sprawling
   epistemic operating system.
2. the design should still preserve the strongest long-range insight: a skill
   can become a portable cognition capsule if its internals are structured
   around better primitives than ordinary RAG.

The most important design shift is this:

- the live serving substrate is `EvidenceSpan`, not `Claim`
- the live answering path is narrow and boring by default
- claims, contradiction analysis, and richer epistemic structures are offline
  derived layers in v1
- provenance is not just a citation list; it is a replayable derivation trace
- query routing should distinguish local from global question shapes before
  spending more reasoning budget
- governance and deployment are separate concerns, with AI Provenance Spec as the
  sister deployment substrate

This makes Grounded RAG v1 much smaller, but also much more honest.

## What Grounded RAG Is

Grounded RAG is a repo-scoped, evidence-backed answering skill for engineers and
maintainers.

From the outside, it should look like a small skill:

- one tool
- narrow interface
- small surface area

Inside, it may contain:

- document ingestion
- evidence span extraction
- retrieval and reranking
- context assembly
- answer synthesis
- replayable provenance traces
- optional offline claimification and contradiction analysis

The project is motivated by a dissatisfaction with conventional RAG stacks,
which usually assume:

- heavy external infrastructure
- chunk-first memory
- opaque prompt logic
- weak provenance
- bolted-on evaluation
- hidden evolution or drift

Grounded RAG is an attempt to get the benefits of retrieval and hidden internal
depth without inheriting all of those defaults.

## What Grounded RAG Is Not

Grounded RAG v1 is not:

- a general epistemic operating system
- a federated memory mesh
- a live model-training platform
- a web-scale crawler
- a broad multi-tenant knowledge service
- a deployment substrate

Those ideas may inform later directions, but they are not part of the first
serious implementation cut.

## Forced V1 Decisions

The following decisions are already forced and should be assumed by reviewers.

### Product identity

Grounded RAG v1 is a repo-scoped answering skill for code and docs.

### First user

The first user is an engineer or maintainer asking questions about one local
codebase and its documentation.

### First corpus

The v1 corpus is limited to:

- source files
- repo docs
- ADRs and design docs
- local config/spec files

It excludes web crawling, chat logs, Jira, Slack, email, and cross-repo shared
memory.

### Canonical object

The canonical epistemic object in v1 is `EvidenceSpan`.

### Public answer states

Every answer must be one of:

- `Grounded`
- `Partial`
- `Abstain`

### Live-path rule

The live path should only:

1. retrieve evidence spans
2. rerank
3. assemble context
4. synthesize an answer
5. emit citations and a replayable trace

### Offline-only rule

The following are offline-only in v1:

- claim extraction
- contradiction consolidation
- benchmark generation
- policy experiments
- compaction
- revocation rebuilds

### Boring mode

The system must always support a degraded, evidence-span-only mode with no
claim dependency and no adaptive evolution.

### Evolution boundary

V1 may evolve retrieval and assembly policies, but not:

- model weights
- the public answer contract
- root ontology types
- provenance schema
- benchmark gold cases

## Smallest Falsifiable Loop

The smallest loop that proves or disproves the architecture is:

1. ingest one repo's code and docs
2. answer engineering questions with direct evidence spans
3. attach replayable traces and citations
4. outperform a simpler span-RAG baseline on usefulness and groundedness
5. survive revocation and degraded-mode fallback

If this loop does not win, the larger Grounded RAG architecture is not earned.

## Key Sister Systems

The proposal depends heavily on understanding three adjacent systems:

- AI Provenance Spec
- Sentinel
- Truth JBT

### AI Provenance Spec Background

#### What it is

AI Provenance Spec is the sister deployment project for portable cognition capsules.

Its own working identity is: a trusted release and deployment substrate for
portable cognition capsules.

Its role is not to make Grounded RAG intelligent. Its role is to make Grounded RAG
deployable with trust.

#### Core mechanism

In the original backstory, AI Provenance Spec rejects the heavy plugin model and
replaces it with ephemeral skill deployment:

- skills are invoked, not installed
- they register what they need on demand
- they execute in session context
- they unregister on completion
- they leave near-zero standing footprint

That basic "drop in, execute, dissolve" idea is the intuitive surface.

Its constitution and v1 scope refine that intuition into something stricter:

- the deployable unit is a `ReleaseEnvelope`
- a release envelope contains payload, manifest, dependency lock,
  compatibility class, and attestation set
- deployability is decided by exact envelope bytes plus exact trust inputs
- deployment always evaluates against a specific `PolicySnapshot` and
  `EnvironmentProfile`
- rollback and revocation are first-class operations, not afterthoughts

#### What makes it compelling

AI Provenance Spec is compelling because it gives Grounded RAG a serious answer to the
question: "How does a hidden-capability skill become a governed runtime object
instead of just a clever local hack?"

Its strongest ideas are:

- explicit deployable unit
- explicit trust unit
- explicit rollback and revocation units
- explicit circuit breakers
- conservative degraded mode
- portability contract that distinguishes what travels with the artifact from
  what remains environmental state

#### Why it matters to Grounded RAG

Grounded RAG is about hidden internal cognition.
AI Provenance Spec is about trusted packaging, release, deployment, rollback, and
revocation for such artifacts.

Without AI Provenance Spec, Grounded RAG can remain an interesting local skill.
With AI Provenance Spec, Grounded RAG can become a deployable cognition capsule with:

- release boundaries
- policy gates
- runtime admission constraints
- rollback discipline
- revocation semantics

This matters because any serious hidden-depth skill eventually needs a credible
deployment and trust story.

### Sentinel Background

Sentinel is the strongest local research substrate discovered so far.

Its most important transferable primitives are:

- a research refinery that converts paper extracts into structured HTML
  explainers
- a citation lattice that maps concepts to formulas, complexity, and system
  components
- reveal surfaces that compress architecture and evidence into inspectable
  artifacts

Sentinel matters because it treats research not as references at the bottom of a
page, but as structured internal substrate.

### Truth JBT Background

Truth JBT is the strongest local governance/control-plane substrate discovered
so far.

Its most important transferable primitives are:

- discovery of agents, skills, hooks, settings, and MCP components as governed
  objects
- telemetry and ranking surfaces
- change history and rollback records
- conflict detection and sync semantics
- explicit visibility and enable/disable states

Truth JBT matters because it treats configuration and deployment-adjacent state
as a governable system, not as loose files and hidden behavior.

## Four Research Findings That Materially Changed The Proposal

The following four findings are the strongest recent conclusions and are now
integrated into the proposal.

### Finding 1: The serving substrate should be EvidenceSpan, not Claim

#### What it is

The project initially drifted toward claim-native memory, with claims treated as
the primary serving object. Recent work and deeper review pushed that back.

The better v1 design is:

- raw source remains first-class
- evidence spans are the canonical live serving object
- claims are derived, offline epistemic objects

#### Why this matters

Claims are interpretations. They compress and normalize source material, which
is useful for verification, evaluation, and later reasoning, but dangerous if
made canonical too early.

If claims dominate the hot path too soon, the system risks:

- freezing extraction mistakes into ontology
- stripping qualifiers and local context
- over-normalizing ambiguity
- making reinterpretation expensive

#### Why this is compelling

This finding keeps v1 honest.

It preserves the possibility of claim-native higher-order reasoning later,
without letting v1 pretend that extraction is already reliable enough to carry
the whole product.

#### External research influence

Microsoft Research's Claimify work, introduced publicly in late 2024 and tied
to the broader GraphRAG line, is especially relevant because it highlights how
valuable high-quality factual claim extraction can be while also implying how
careful the extraction step must be.

#### Design impact

This finding directly caused the following forced decisions:

- `EvidenceSpan` is the canonical v1 object
- `Claim` is offline-only and feature-gated
- boring mode depends only on evidence spans
- the live loop is narrower and easier to test

### Finding 2: Provenance must be a derivation trace, not just citations

#### What it is

The system originally spoke about citations and provenance in a loose way.
Recent research made the requirement much sharper:

- provenance is not just "here are the sources"
- provenance must support replay
- provenance must localize where unsupported content entered the workflow

#### Why this matters

In a multi-step answering system, the hardest problem is often not that the
answer is unsupported. It is determining where the unsupported content was
introduced:

- bad retrieval
- bad extraction
- bad routing
- bad synthesis
- stale source

If the trace cannot localize failure, auditability becomes theater.

#### Why this is compelling

This is one of the strongest differentiators for Grounded RAG.

A system that can not only answer, but also show the exact derivation path and
replay the decision boundary, has a much stronger trust story than ordinary
RAG.

#### External research influence

Microsoft Research's VeriTrail work from August 2025 is especially important
here. Its key move is not just hallucination detection; it is traceability with
fault localization in multi-step AI workflows.

#### Design impact

This finding directly caused the following decisions:

- every answer must carry a snapshot id
- every non-abstaining answer must expose cited evidence spans
- replayable `RetrievalTrace` and `AnswerAuditRecord` objects are mandatory
- revocation and rollback need durable record semantics

### Finding 3: Retrieval should be query-topology aware

#### What it is

Not all questions are the same.

Some are local:

- "Where is auth checked?"
- "What does this function return?"

Some are global:

- "What changed across the architecture in the last two weeks?"
- "Where are the main coupling points in this repo?"

Treating both with the same retrieval posture is inefficient and often wrong.

#### Why this matters

A local question benefits from:

- tight evidence spans
- narrow reranking
- low latency

A global question may need:

- broader retrieval
- structural summarization
- graph-like aggregation
- higher synthesis budget

#### Why this is compelling

This finding suggests that Grounded RAG's intelligence should not come only from
"better retrieval." It should also come from deciding what kind of retrieval
problem the query actually is.

That makes the system more adaptive without requiring immediate model
self-improvement.

#### External research influence

This is influenced by BenchmarkQED and GraphRAG, especially the distinction
between local and global question patterns and the broader idea that corpus-wide
questions reward different retrieval strategies than narrow lookup questions.

#### Design impact

This finding directly caused the proposal to include:

- query-topology-aware routing as an explicit design concern
- a narrower live loop for local questions
- a caution that the topology classifier itself is a high-leverage failure
  source and must not silently dominate the system

### Classifier failure protocol (mandatory)

- confidence below configurable threshold (default: 0.6) → route to `local`
- exception or timeout → route to `local`
- hard timeout on classifier: 100ms; exceeded → default to `local`
- in all fallback cases, `RetrievalTrace` must record
  `topology_classified: false` and `topology_fallback_reason`

The classifier is a heuristic aid. Any implementation that allows classifier
failure to block serving is non-conformant with this proposal.

### Finding 5 (new): Multi-Resolution Index and MDL Span Selection

Two information-theoretic findings now shape the retrieval and assembly steps:

**Multi-resolution index (RGMem pattern):** Retrieval operates against a
five-layer hierarchical index. In v1, only L0 (BM25/token) and L1
(statement-level embeddings, current behavior) are active. Layers L2–L4
(function, module, subsystem) are reserved. Query topology routing selects
which layers to engage: local queries use L1; global queries may engage L2+
when available. This yields 40% context reduction at equivalent accuracy by
avoiding redundant low-level spans when a higher-level summary suffices.

**MDL span selection:** After reranking, final context assembly is governed
by a greedy MDL selector rather than raw cosine rank. The selector maximizes
information gain about the query per context-window token, stopping when
marginal gain falls below 1 bit per token. This eliminates spans that add
tokens without reducing description length. It replaces simple top-k cutoffs
in the assembly step.

### Finding 4: The strongest architecture is a two-plane system

#### What it is

The strongest synthesis so far is:

- Sentinel supplies the distillation and knowledge-refinery plane
- Truth JBT supplies the governance and control-plane semantics
- AI Provenance Spec supplies the release and deployment substrate

Grounded RAG itself should sit between them as the answering capsule.

#### Why this matters

Many systems try to solve everything inside one runtime:

- ingestion
- retrieval
- governance
- deployment
- evolution
- trust

That tends to produce a dense, opaque monolith.

The better structure is:

- one plane that metabolizes knowledge
- one plane that governs change and state
- one plane that handles trusted release and deployment

#### Why this is compelling

This is what makes the overall ecosystem start to look like a new systems
primitive rather than "RAG with extra steps."

It lets Grounded RAG remain small at the surface while depending on adjacent
systems for:

- structured distillation
- operator control
- audit history
- packaging and runtime trust

#### Design impact

This finding directly caused the proposal to:

- avoid loading every governance concern into the live Grounded RAG runtime
- treat AI Provenance Spec as the deploy/release substrate
- treat Sentinel as the distillation substrate
- treat Truth JBT as the governance inspiration

## Integrated Proposal

The proposal, after all forced decisions and research integration, is:

### Core thesis

Grounded RAG v1 should be a repo-scoped, evidence-backed answering capsule that
uses a narrow live loop and a richer offline epistemic layer.

### Live answering path

The live path is intentionally boring:

1. select candidate evidence spans from the repo corpus
2. rerank them using the hidden reranker role
3. select final spans using MDL-optimal greedy selection: maximize
   `I(E;Q) / token_cost(E)` (information gain about query per
   context-window token); stop when marginal gain < 1 bit per token
4. synthesize an answer
5. emit citations, coverage state, `EpistemicStatus` summary,
   `uncertainty_interval`, `confidence_tier` of highest-cited span,
   and snapshot id

### Offline epistemic path

Offline work may build richer structure:

- claim extraction
- contradiction consolidation
- benchmark generation
- revocation rebuilds
- retrieval policy experiments

This plane is important, but it is not allowed to dominate the hot path in v1.

### Provenance path

Every served answer should produce enough durable trace to support:

- replay
- audit
- fault localization
- revocation impact analysis

### Minimum reveal surface specification

The reveal surface must expose at minimum seven fields per non-abstaining answer:
- `span_ids_cited`: ordered list of cited `EvidenceSpan` identifiers,
  each annotated with its `confidence_tier`
- `coverage_state`: single emitted coverage state
- `topology_route_used`: `local`, `global`, or `unclassified`
- `snapshot_id`: `PolicySnapshot` identifier
- `answer_state`: `Grounded`, `Partial`, or `Abstain`
- `epistemic_status`: object with `conflict_type`, `conflict_degree`,
  and `extension_count` (replaces boolean `contradiction_flag`)
- `uncertainty_interval`: `[Bel, Pl]` pair from Dempster-Shafer
  combination of cited spans' BPA vectors

A reveal surface omitting any of these seven fields is non-conformant.
Deeper audit data lives in `RetrievalTrace` and `AnswerAuditRecord`.

### Query-topology path

The system should eventually distinguish at least:

- local evidence lookup
- broader synthesis questions

But the classifier must be treated as a fallible routing aid, not as a hidden
oracle.

### Governance path

Grounded RAG should inherit governance discipline from the constitution and from
Truth JBT-style control-plane ideas:

- explicit durable objects
- explicit rollback unit
- explicit revocation semantics
- explicit boring mode
- explicit decision rights

### Deployment path

When Grounded RAG leaves local development, AI Provenance Spec should be the substrate
that packages, attests, deploys, rolls back, and revokes it as a portable
cognition capsule.

## Why This Architecture Is Special

The proposal is special for four reasons.

1. It refuses the usual chunk-first ontology and instead anchors the live product
   on replayable evidence spans.
2. It treats provenance as a derivation problem, not a formatting problem.
3. It uses research distillation and governance as separate imported strengths
   rather than trying to rebuild both poorly inside one runtime.
4. It narrows the first cut enough to be falsifiable while preserving a path to
   much richer later systems.

### Falsifiability status

| Claim | Falsifiable in v1                              | Requires               |
|-------|------------------------------------------------|------------------------|
| 1     | Yes                                            | Tracks A, B, C         |
| 2     | Yes                                            | Tracks D, G            |
| 3     | Partially — boundary defined, not exercised    | Track H interface spec |
| 4     | Yes                                            | Kill criteria          |

Claim 3 is a v1 boundary definition, not a v1 proof. The full two-plane
system cannot be validated until AI Provenance Spec integration is exercised. This
must not be presented to reviewers as a v1 deliverable.

## What Another Model Should Critique

If this proposal is reviewed by another strong model, the most useful attack
surfaces are:

### Product fit

- Is the v1 product identity narrow enough?
- Is the smallest falsifiable loop actually sufficient to validate the thesis?
- Is the answer contract precise enough?

### Object model

- Is `EvidenceSpan` the right canonical v1 object?
- Are claims correctly demoted to an offline derived layer?
- Are the durable objects minimal and sufficient?

### Provenance and audit

- Is the replay and derivation model realistic?
- Is the provenance burden underpriced?
- Are revocation and rollback semantics strong enough?

### Routing and retrieval

- Is query-topology-aware routing worth the added complexity?
- Is the topology classifier a dangerous choke point?
- What simpler baseline should Grounded RAG be measured against?

### Ecosystem boundaries

- Is the split between Grounded RAG, Sentinel, Truth JBT, and AI Provenance Spec clean?
- Are we importing useful primitives or just borrowing strong metaphors?
- Does AI Provenance Spec carry the right deployment responsibilities?

### Failure and degradation

- Is boring mode actually usable?
- Are abstention conditions strong enough?
- Are there any fail-open paths hidden by complexity?

## Explicit Reviewer Context

The following assumptions are currently in force:

- Grounded RAG uses fully local sentence-transformers models (BAAI/bge-small-en-v1.5 embedder,
  cross-encoder/ms-marco-MiniLM-L-6-v2 reranker) — no external API calls.
- AI Provenance Spec is the intended deployment substrate for capsule-like skills.
- Sentinel is the strongest local research-refinery reference.
- Truth JBT is the strongest local governance/control-plane reference.
- The most recent external research that materially changed the plan came from
  the GraphRAG, Claimify, BenchmarkQED, and VeriTrail line at Microsoft
  Research.

## Sources That Shaped This Proposal

Local project docs:

- `README.md`
- `CLAUDE.md`
- `docs/backstory.md`
- `docs/constitution.md`
- `docs/v1-scope.md`
- Sister deployment-substrate specification (AI Provenance Spec): README, governance docs (constitution, backstory), v1-scope
- Local research-refinery prototype: citation data, docs-generator, atlas page
- Local governance / control-plane prototype: architecture overview, discovery service, telemetry data, sync/conflict utilities

External research anchors:

- GraphRAG
- Claimify
- BenchmarkQED
- VeriTrail
- W3C PROV
- ArgRAG (arXiv:2508.20131) — argumentation-theoretic RAG, direct basis for EpistemicStatus
- RGMem (arXiv:2510.16392) — renormalization-group memory, basis for five-layer index
- Dempster-Shafer Theory of Evidence (Shafer 1976; Yager 1987 normalization)
- Dung 1995 Argumentation Frameworks — basis for conflict_type taxonomy
- Pollock 1987 Defeasible Reasoning — rebutting vs undercutting distinction
- Cowan 2001 Working Memory — basis for 4±1 cognitive load ceiling

## Bottom Line

The proposal now rests on a more disciplined statement:

Grounded RAG v1 is not trying to prove that a full epistemic operating system can
fit inside a skill. It is trying to prove that a small skill can answer from
anchored evidence, expose replayable provenance, survive revocation and
degraded-mode fallback, and still preserve a path toward deeper internal
cognition later.
