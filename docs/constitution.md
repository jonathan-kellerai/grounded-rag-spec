# Grounded RAG Constitution

## Purpose

This document fixes the non-negotiable structural rules for Grounded RAG so the
project stops drifting into an unbounded architecture research exercise.

Grounded RAG v1 is a repo-scoped, evidence-backed answering skill for code and
docs. Governance exists to improve answer integrity, not as an end in itself.

## Objective Hierarchy

When goals conflict, this priority order is binding:

1. Legal, privacy, and license compliance
2. Grounded correctness
3. Useful answer quality
4. Replayability and provenance
5. Latency and cost
6. Adaptive improvement speed
7. Portability

Higher-priority objectives always win over lower-priority objectives.

### Hard Constraint: Runtime Self-Containment

Runtime self-containment is a co-equal hard constraint alongside objective #2 (Grounded correctness).
Grounded RAG must function without any external API calls, network services, or running daemons at inference time.
This constraint cannot be traded off against any lower-priority objective in the hierarchy.

Steady-state inference must be fully offline-capable.
One-time initialization (e.g., model weight download on first run) is permitted but must be documented, bounded, and air-gap-stageable.
Deployment-time dependencies (Aegis Drop registration, policy bundle signing) are outside the scope of this constraint.

**Rationale:** Portability (objective #7) previously implied self-containment, but self-containment is more precisely a prerequisite for correctness guarantees — a system that can fail at inference time due to an unavailable external service cannot reliably provide grounded answers.
Elevated by ADR-011.

## Core Invariants

The following rules are mandatory in v1:

1. No answer is served without anchored evidence unless it is an explicit
   abstention.
2. No source is admitted without an explicit source-class policy.
3. No durable evolution occurs without a versioned `PolicySnapshot`.
4. Every served answer must be replayable against a specific snapshot id.
5. Every non-abstaining answer must expose cited evidence spans.
6. Every source revocation must make revoked material unavailable for future
   serving.
7. The system must support a boring degraded mode that remains usable when
   higher-order machinery is disabled.

## Deployment and Ownership Units

### Unit of deployment

One Grounded RAG deployment equals one named corpus package with one operator
group and one policy bundle.

For v1, that corpus package is one repo/workspace.

### Unit of ownership

Decision rights are explicit:

- `Corpus Owner`: source admission, retention, revocation
- `Skill Architect`: answer contract, ontology root types, reveal surface
- `Release Authority`: policy promotion, benchmark approval, evolution enablement
- `Incident Owner`: circuit breakers and emergency rollback

One person may hold multiple roles, but the roles themselves must remain
distinct.

## Public Contract

Grounded RAG is centered on answering from anchored evidence.

Every response must be one of:

- `Grounded`
- `Partial`
- `Abstain`

### Evidence thresholds

`Grounded` requires ALL of the following:
- at least two independently anchored `EvidenceSpan` references that together
  cover the core of the answer, OR one span that is self-contained and directly
  and completely answers the question without synthesis across gaps
- no unresolved coverage gap on the central question
- no active `EpistemicStatus` with `conflict_type` other than `none` on any
  cited span, AND `extension_count` must equal 0 for a `Grounded` classification
- all cited spans must carry `confidence_tier` of `PREPONDERANCE` or higher

`Partial` requires ALL of the following:
- at least one anchored `EvidenceSpan` reference
- at least one of: coverage gaps remain, synthesis crosses an unsupported
  inference step, or any cited span has `EpistemicStatus.conflict_type != "none"`,
  or no cited span reaches `PREPONDERANCE` confidence tier

An answer that meets neither threshold must be `Abstain`.

Every non-abstaining response must include:

- a natural-language answer
- cited `EvidenceSpan` references
- a coverage state
- an `EpistemicStatus` summary (surfaced as `conflict_type` and `extension_count`
  at minimum; full `accepted_span_ids` / `defeated_span_ids` in the audit record)
- an `uncertainty_interval` as a `[Bel, Pl]` pair derived from BPA combination
- a snapshot id

## Coverage and Uncertainty

### Coverage states

Coverage is represented by exactly one of:

- `covered_direct`
- `covered_partial`
- `searched_none`
- `not_searched`
- `forbidden`
- `stale`

### Uncertainty model

V1 does not expose one fake unified confidence score.

Internally, uncertainty is tracked as separate dimensions:

- `evidence_strength`
- `coverage_quality`
- `source_trust`
- `epistemic_conflict` (replaces `contradiction_pressure`; tracks
  `conflict_type`, `conflict_degree`, and `extension_count` per
  Dung argumentation semantics)
- `synthesis_distance`
- `bpa_combined` (Dempster-Shafer belief/plausibility interval after
  combining all cited span BPA vectors; Yager normalization applied
  when conflict mass K > 0.5)

Publicly, uncertainty is surfaced through answer state, coverage, and
`EpistemicStatus` summary and `uncertainty_interval`.

## Canonical and Durable Objects

### Canonical object

The canonical epistemic object in v1 is `EvidenceSpan`, not `Claim`.

An `EvidenceSpan` is a source-anchored, versioned slice of content with
provenance.

Every `EvidenceSpan` carries:
- a bitemporal identity tuple: `(content_hash, valid_start_commit,
  valid_end_commit, tx_start, tx_end)` where `valid_time` tracks when
  the content was true in the source and `tx_time` tracks when
  Grounded RAG indexed it
- a `ProvenanceLedger`: hash-linked chain from source document through
  chunk algorithm, embedding, reranking, to assembly position
- a `bpa_vector` and `uncertainty_interval` for Dempster-Shafer scoring
- a `confidence_tier` of `REASONABLE_SUSPICION`, `PREPONDERANCE`, or
  `BEYOND_REASONABLE_DOUBT`
- an `EpistemicStatus` recording dialectical conflict state

### Required durable objects

The required durable object set for v1 is:

- `SourceRecord`
- `SourceVersion`
- `EvidenceSpan`
- `PolicySnapshot`
- `BenchmarkCase`
- `RetrievalTrace`
- `RevocationRecord`
- `AnswerAuditRecord`
- `ArchitectureDecisionRecord`

An `ArchitectureDecisionRecord` is created for every constitution amendment
and every change to a forced decision in `docs/v1-scope.md`. It records:
the clause changed, author and date, reason, migration impact, and rollback
plan. Constitution amendments without a corresponding record are invalid.

`Claim`, `Entity`, and `Contradiction` are derived experimental objects in v1.
They are offline-only and feature-gated.

## Online and Offline Split

The live path may only do the following:

- retrieve evidence spans
- rerank
- synthesize an answer
- attach provenance
- write a minimal audit record

The following are offline-only in v1:

- claim extraction
- contradiction consolidation
- benchmark generation
- policy experimentation
- compaction
- revocation cascade rebuilds

## Feedback Loop

The sanctioned path for triggering retrieval heuristic improvement in v1:

1. Every `AnswerAuditRecord` includes a `user_signal` field:
   `accepted`, `rejected`, or `unchecked`.
2. A `Grounded` answer that receives `rejected` creates an offline review
   queue item referencing the record and its `RetrievalTrace`.
3. Review queue items unacted on within 30 days are logged as expired.
   Expiry itself is counted in operator review load.
4. Approved findings feed into retrieval heuristic change proposals that
   must go through a `PolicySnapshot` promotion.

This is the only sanctioned path for retrieval policy improvement in v1.

## Circuit Breakers

The system must support independent hard stops for:

- new source admission
- durable writes
- policy promotion
- derived-object generation
- answering outside boring mode
- `AUTOIMMUNE_FAILURE`: new document sources that persistently trigger
  the autoreactive semantic collision check during the source
  burn-in period (10 queries); fires `closed → open` on the
  new source admission breaker for the offending source class

### Circuit breaker states

Each breaker operates in one of three states:
- `closed`: normal operation
- `open`: hard stop, guarded function is blocked
- `half-open`: operator-supervised, may execute under observation

### Transitions

| Transition         | Trigger                              | Authority            |
|--------------------|--------------------------------------|----------------------|
| closed → open      | automatic on defined condition       | system               |
| open → half-open   | explicit written action              | `Incident Owner`     |
| half-open → closed | explicit approval after observation  | `Release Authority`  |
| half-open → open   | re-trigger during observation        | system               |

A breaker must never transition from `open` directly to `closed`. Each
transition must be written to a durable log: timestamp, breaker name,
from-state, to-state, actor identity.

## Boring Mode

Grounded RAG must always support a reduced mode with:

- evidence-span retrieval only
- fixed synthesis template
- no claim usage
- no policy evolution
- no dependency on offline-derived objects

If higher-order machinery is impaired, the system must fall back to boring mode
rather than fail open.

## Portability Contract

By default, a portable Grounded RAG artifact carries:

- prompts
- policy definitions
- ontology root schema
- benchmark definitions
- reveal templates
- feature flags

It does not automatically carry corpus-derived state.

Derived state is portable only through an explicit, signed snapshot export.

## Amendment Rule

This constitution may be changed only through an explicit architecture decision
that names:

- the clause being changed
- the reason for change
- the migration impact
- the rollback plan

Constitution changes are not to be smuggled in through incidental implementation
work.
