# Grounded RAG — v1 Architecture Specification

Grounded RAG is a repo-scoped, evidence-grounded retrieval-and-answer system:
given a question about a body of source material, it returns an answer grounded
in cited evidence, or it declines to answer. This site publishes the **v1
architecture specification** — a design-phase document set, not an
implementation.

> **Design phase.** No implementation, no benchmarks. Every performance figure
> in these documents is a prospective target, never a measured result.

## Start here

- [Proposal](proposal.md) — what Grounded RAG is and why it exists.
- [Constitution](constitution.md) — the non-negotiable design principles.
- [v1 Scope](v1-scope.md) — what v1 includes and excludes.
- [Architecture Decision Records](ADR.md) — the eleven ADRs and their amendment chain.

## Whitepapers

- [Technical whitepaper](whitepapers/grounded-rag-v1-technical.md) — the full design.
- [Marketing overview](whitepapers/grounded-rag-v1-marketing.md) — the non-technical summary.

## Research foundation

- [Epistemic active-learning synthesis](research/epistemic-active-learning-research-synthesis.md)
- [Active-epistemic implementation guide](research/active-epistemic-implementation-guide.md)
- [Temporal-provenance synthesis](research/temporal-provenance-research-synthesis.md)

## Background

- [Backstory](backstory.md) — how the project arrived at its name and framing.
- [Beads work-breakdown spec](grounded-rag-v1-beads-spec.md) — the v1 work items.

---

The repository source is at
<https://github.com/jonathan-kellerai/grounded-rag-spec>. Agents working in the
repository should start at `AGENTS.md`. Licensed under Apache-2.0.
