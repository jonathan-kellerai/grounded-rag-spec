# Glossary — grounded-rag-spec

Load-bearing vocabulary for the Grounded RAG v1 specification. Each entry is one
paragraph. Definitions are grounded in the technical whitepaper
(`docs/whitepapers/grounded-rag-v1-technical.md`); citations point at the defining
passage. Tier-2 detail for [AGENTS.md](../../AGENTS.md).

## Grounded / Partial / Abstain

The three-state answer contract — the only three response modes Grounded RAG may
emit (`docs/whitepapers/grounded-rag-v1-technical.md:175-181`). **Grounded** means
the answer is fully supported: at least two independently anchored evidence
spans (or one self-contained span), no unresolved coverage gap, no active
conflict, and all cited spans at the PREPONDERANCE confidence tier or higher.
**Partial** means the answer is supported but incomplete — a coverage gap, an
unsupported synthesis step, a conflict, or sub-threshold confidence. **Abstain**
means the system declines to answer: no supporting evidence, policy-forbidden
material, an unresolved high-impact contradiction, or degraded safety mode.

## EvidenceSpan

The canonical epistemic object Grounded RAG serves — deliberately not a `Claim`
(`docs/whitepapers/grounded-rag-v1-technical.md:159-167`). An `EvidenceSpan` is a
text span directly observable in a source document and directly revocable when
that source changes. Each span carries a bitemporal identity tuple, a
`ProvenanceLedger`, a `bpa_vector` (Dempster-Shafer mass over the three answer
states), an `uncertainty_interval` `[Bel, Pl]`, a `confidence_tier`, and an
`EpistemicStatus` recording any dialectical conflict. The design serves spans
rather than claims because a claim is a transformed artifact that may not
survive source mutation cleanly.

## ProvenanceLedger

A five-step, hash-linked chain recorded on every `EvidenceSpan` that makes
tampering detectable without a separate signature scheme
(`docs/whitepapers/grounded-rag-v1-technical.md:221-233`). The chain links chunk
algorithm → embedding model → reranking → assembly position; the final
`ledger_hash` is stored on the span, and modifying any field in the chain
invalidates it. The W3C PROV-DM vocabulary applies at every step.

## BPA (Basic Probability Assignment)

The Dempster-Shafer mass function Grounded RAG uses in place of a single
calibrated confidence score, committed by ADR-008
(`docs/whitepapers/grounded-rag-v1-technical.md:183-196`). A BPA assigns
probability mass over the frame Θ = {Grounded, Partial, Abstain}, with a
residual "ignorance mass" on Θ itself — the open-world acknowledgement that some
belief is uncommitted to any single state. Six internal dimensions feed the
BPA; only an aggregated form is surfaced publicly.

## [Bel, Pl] — Belief and Plausibility interval

The publicly emitted `uncertainty_interval`: a pair of numbers giving the lower
(Belief) and upper (Plausibility) bound of confidence in an answer state,
computed from the combined BPA
(`docs/whitepapers/grounded-rag-v1-technical.md:197-198`). Callers may threshold
on `Bel` for their own inclusion decisions; Grounded RAG deliberately does not
guess the caller's threshold.

## Boring Mode

A mandatory degraded-operation fallback and explicit safety guarantee
(`docs/whitepapers/grounded-rag-v1-technical.md:495-500`). When higher-order
machinery is impaired, the system falls back to Boring Mode rather than failing
open. In Boring Mode it serves only evidence-span retrieval, synthesizes through
a fixed template, uses no claim objects, performs no policy evolution, and
depends on no offline-derived objects. The acceptance criterion is explicit: the
system fails closed into Boring Mode rather than failing open.

## Circuit breaker

One of six role-gated fail-safe mechanisms governing the system
(`docs/whitepapers/grounded-rag-v1-technical.md:453-475`). A breaker opens to halt
serving when a safety condition is violated; state transitions follow strict
rules and are written to a durable breaker log. A breaker must never transition
directly from `open` to `closed` — each reset is an explicit, audited action.

## ADR amendment chain (ADR-005 → ADR-009 → ADR-011)

The worked example of supersession discipline in `docs/ADR.md`. **ADR-005**
specified embedding and reranking via an external gateway; it was **superseded
by ADR-009**, which switched to bundled local models (`bge-small-en-v1.5` plus a
MiniLM cross-encoder) and a local vector store to achieve runtime
self-containment. **ADR-011** then amended the constitution itself, elevating
runtime self-containment from a portability preference to a hard constraint
co-equal with grounded correctness. No ADR in the chain was rewritten in place —
each superseded record is preserved. See [conventions.md](conventions.md).
