# Grounded RAG — v1 Architecture Specification

Grounded RAG is a repo-scoped, evidence-backed answering skill: given a question
about a body of source material, it returns an answer that is *grounded in
cited evidence* or it declines to answer. This repository is the **architecture
specification** for Grounded RAG v1 — the constitution, the proposal, the
architecture decision records, the research synthesis, and the technical
whitepaper. It contains **no implementation**: no source code, no benchmarks, no
deployment artifacts. What it contains is a design and the reasoning trail
behind every load-bearing decision. The technical whitepaper notes one
unresolved architectural question; readers should consult §10.1 for details.

> **Status — design phase.** No implementation, no benchmarks. Every
> performance target in this repository is *prospective*. The
> "15 % better than a BM25 baseline" figure in §9 of the technical whitepaper is
> a **kill criterion** — a provisional engineering threshold informed by initial
> RAG benchmark review, to be refined during prototyping — not a reported result.
> Nothing here has been measured.

> **Known Architectural Gap:** The synthesis step (T2's answer drafting)
> has no named generative model. Technical Whitepaper §10.1 documents
> three candidate resolutions (host-LLM delegation, bundled local SLM,
> template-only); none is confirmed. Until resolved, the runtime
> self-containment hard constraint (ADR-011) may require amendment.
> Readers working toward implementation should treat this as an open
> design question requiring amendment before v1 execution begins.

---

## Table of Contents

- [What Grounded RAG Is](#what-grounded-rag-is)
- [The Three-Layer Nesting](#the-three-layer-nesting)
- [The Three-State Answer Contract](#the-three-state-answer-contract)
- [Three-State Circuit Breakers](#three-state-circuit-breakers)
- [Belief Under Uncertainty: Dempster-Shafer](#belief-under-uncertainty-dempster-shafer)
- [Evidence and Replayability](#evidence-and-replayability)
- [Disciplined Amendment: the ADR Amendment Chain](#disciplined-amendment-the-adr-amendment-chain)
- [Research Foundation](#research-foundation)
- [Standards Alignment](#standards-alignment)
- [Repository Layout](#repository-layout)
- [Sister Specification: AI Provenance Spec](#sister-specification-ai-provenance-spec)
- [Who This Specification Is For](#who-this-specification-is-for)
- [License and Attribution](#license-and-attribution)

---

## What Grounded RAG Is

The name is the design. A nesting doll nests smaller shells inside larger
ones; the Grounded RAG architecture nests three answering layers, each one a
self-contained shell that can be inspected, tested, and reasoned about on its
own. An answer is never produced by an opaque monolith — it is produced by a
known sequence of layers, each with an explicit contract, and the final answer
carries the evidence that justifies it.

Two properties separate Grounded RAG from a conventional retrieval-augmented
generation pipeline:

1. **An answer is a typed object, not a string.** It is one of three discrete
   states, and it carries a provenance ledger that lets any reviewer replay how
   it was reached.
2. **Declining is a first-class outcome.** Abstaining when the evidence does not
   support an answer is correct behavior, not failure. The architecture is
   built so that the cheap, safe path is also the default path.

---

## The Three-Layer Nesting

Grounded RAG answers through three nested layers. Each layer is a shell with a
single responsibility and a defined interface to the layer it wraps.

- **T1 — the shell (≤ ~80 tokens).** A tiny outermost gate. It classifies the
  request, enforces the token budget, and decides whether the question can be
  answered cheaply, must descend into retrieval, or should be refused outright.
  Keeping T1 under roughly 80 tokens keeps the common path fast and auditable.
- **T2 — the RAG pipeline.** The retrieval-augmented generation layer: it
  retrieves candidate evidence, assembles context, and drafts a grounded
  answer. T2 is where evidence is gathered and where the answer's first claim to
  groundedness is established.
- **T3 — dual encoder-only SLMs.** Two small encoder-only language models that
  perform the discriminative work T2's generation cannot self-certify: scoring
  evidence relevance and verifying that the drafted answer is actually entailed
  by the cited spans. Encoder-only models are used here deliberately — the task
  is judgement, not generation.

A request descends only as far as it needs to. Most requests are resolved or
refused at T1; the layered design means cost and risk scale with the difficulty
of the question, not with a fixed worst-case path.

---

## The Three-State Answer Contract

Every Grounded RAG answer is exactly one of three states:

| State | Meaning |
| --- | --- |
| **Grounded** | The answer is fully supported by cited evidence. |
| **Partial** | Some of the answer is supported; the unsupported part is explicitly bounded. |
| **Abstain** | The evidence does not support an answer; the system declines. |

This is the central contract of the architecture, framed in **ADR-002**. The
design choice is to use **discrete states rather than a floating-point
confidence score**. A float confidence — "0.73" — is not machine-testable: there
is no principled, stable threshold at which 0.73 becomes "good enough", and two
systems reporting 0.73 are not making a comparable claim. A discrete state *is*
testable. "Did this answer return Grounded when the evidence supported only a
Partial answer?" is a question a test suite can ask and a reviewer can
adjudicate. The three-state contract turns answer quality into something that
can be asserted, regression-tested, and audited.

---

## Three-State Circuit Breakers

Grounded RAG's operational safety rests on circuit breakers that are themselves
three-state, and the legal transitions between those states are **role-gated
constitutional commitments** of the architecture — each transition requires
explicit authorization and audit-logged entry:

```
closed  ──►  open  ──►  half-open  ──►  closed
  ▲                          │
  └──────────────────────────┘   (only via half-open)
```

A breaker moves `closed → open` when a failure threshold is crossed,
`open → half-open` after a cooldown, and `half-open → closed` only after a
probe succeeds. The guarantee is that a breaker **never transitions directly
from `half-open` back to a state that skips re-validation** — recovery is always
mediated by the half-open probe. There is no path that lets a degraded
subsystem be silently treated as healthy. When breakers are open, Grounded RAG
enters **Boring Mode**: a fail-closed posture in which it does the safe,
minimal, well-understood thing rather than the clever thing.

---

## Belief Under Uncertainty: Dempster-Shafer

Grounded RAG does not collapse evidence into a single scalar. It models belief
with **Dempster-Shafer theory**, assigning a **Basic Probability Assignment
(BPA)** over the frame of discernment:

```
Θ = { Grounded, Partial, Abstain }
```

Multiple evidence sources each contribute a BPA, and those assignments are
combined. Because real evidence often *conflicts* — one source supports
Grounded, another supports Abstain — Grounded RAG uses **Yager's modified
combination rule** under high conflict rather than the classical Dempster rule.
Yager's rule assigns conflicting mass to the universal set (ignorance) instead
of normalizing it away, which prevents the well-known failure mode where highly
conflicting sources produce a falsely confident combined belief.

The **public surface** of this machinery is deliberately small: a Grounded RAG
answer exposes a **`[Bel, Pl]` interval** — the belief and plausibility bounds
for the reported state. `Bel` is the evidence that *must* support the state;
`Pl` is the evidence that is *consistent with* it. The width of the interval is
itself a signal: a wide `[Bel, Pl]` is the architecture telling the caller that
the evidence is genuinely ambiguous.

---

## Evidence and Replayability

An answer that cannot be audited is not, for Grounded RAG's purposes, an answer.
Two structures make every answer replayable.

- **Bitemporal `EvidenceSpan`.** Each piece of cited evidence is a span tracked
  along **two independent time axes**: *valid time* (when the fact was true in
  the world) and *transaction time* (when the system recorded it). Bitemporal
  modeling means Grounded RAG can answer not only "what does the evidence say" but
  "what did the evidence say *as of* a given date, given what we knew *then*."
  Corrections never overwrite history; they append.
- **Hash-linked `ProvenanceLedger`.** Every answer carries a five-step ledger —
  a hash-linked chain recording retrieval, scoring, drafting, verification, and
  state assignment. Because each step is hash-linked to the previous one, the
  ledger is tamper-evident: a reviewer can replay the chain and confirm the
  reported answer state was actually the one the evidence and the rules
  produced.

Together these make a Grounded RAG answer a *reproducible artifact*. The same
question against the same evidence as-of the same time yields the same answer,
and the ledger proves it.

---

## Disciplined Amendment: the ADR Amendment Chain

Architecture decisions in this repository are not silently rewritten. When a
decision changes, the original ADR is **superseded** by a new one, and the
chain is preserved. The clearest example is the amendment chain
**ADR-005 → ADR-009 (supersession) → ADR-011 (constitution amendment)**.

ADR-005 introduced Runtime Self-Containment as a design preference. Through
ADR-009 and finally **ADR-011**, that preference was **elevated to a hard
constraint, co-equal with Grounded Correctness** — meaning a Grounded RAG
deployment that cannot run self-contained is as non-compliant as one that
returns ungrounded answers. The point is not the specific decision; it is the
*method*. The chain is left intact in `docs/ADR.md` so that any reader can see
not just what the architecture decided, but how its reasoning evolved and what
earlier position each amendment replaced. This is auditable amendment: the
history is the evidence that the design was disciplined.

---

## Research Foundation

The technical whitepaper integrates 22 references, including 19 peer-reviewed
academic papers and 3 model-card / software references. The design is not
invented from scratch — each major mechanism traces to published work.
Representative anchors:

- **ArgRAG** (arXiv:2508.20131) — argumentation-structured retrieval-augmented
  generation.
- **RGMem** (arXiv:2510.16392) — retrieval-grounded memory.
- **VeriTrail** (arXiv:2505.21786) — traceable verification of generated
  answers.
- **Jensen & Snodgrass** — the foundational treatment of bitemporal data,
  behind the `EvidenceSpan` two-axis model.
- **W3C PROV-DM** — the provenance data model informing the
  `ProvenanceLedger`.
- **Pollock** — defeasible reasoning, the basis for treating evidence as
  defeasible support rather than proof.
- **Dung** — abstract argumentation semantics, behind conflict handling in the
  belief layer.

The full reference list, with every citation tied to the mechanism it
justifies, is in the
[technical whitepaper's References section](docs/whitepapers/grounded-rag-v1-technical.md#references).

---

## Standards Alignment

Grounded RAG's architecture was **designed toward** recognized AI-assurance
frameworks. Mechanisms selected address the patterns these frameworks
emphasize:

- **NIST AI 600-1** — the three-state contract and abstain-by-default behavior
  directly address the *confabulation* risk the framework names; the
  provenance ledger is the evidence pattern.
- **DoD Responsible AI, Tenet 4 (Traceability)** — the hash-linked
  `ProvenanceLedger` and bitemporal `EvidenceSpan` are built to satisfy
  traceability: every answer can be decomposed into its sources and steps.
- **FAA AI Concepts of Operations / CSTA Issue Paper** — the ledger is designed
  as an *audit-evidence payload*: a self-contained, replayable record suitable
  for the audit posture that safety-critical aviation guidance expects.

This is design-phase alignment — the system has not been implemented or
evaluated. Actual conformance will be assessed only after benchmarking.

---

## Repository Layout

```
grounded-rag-spec/
├── README.md          — this file
├── LICENSE            — Apache-2.0
├── AGENTS.md          — entry point for AI agents
├── CLAUDE.md          — Claude Code instructions (imports AGENTS.md)
├── NOTICE             — attribution notice
├── CONTRIBUTING.md    — how to contribute
└── docs/
    ├── constitution.md
    ├── proposal.md
    ├── v1-scope.md
    ├── ADR.md
    ├── backstory.md
    ├── grounded-rag-v1-beads-spec.md
    ├── agents/
    ├── whitepapers/
    │   ├── grounded-rag-v1-technical.md
    │   └── grounded-rag-v1-marketing.md
    └── research/
        ├── active-epistemic-implementation-guide.md
        ├── epistemic-active-learning-research-synthesis.md
        └── temporal-provenance-research-synthesis.md
```

- **[docs/constitution.md](docs/constitution.md)** — the objective hierarchy and
  the core invariants; the non-negotiable rules every layer must uphold.
- **[docs/proposal.md](docs/proposal.md)** — the originating proposal: the
  problem, the rationale, and the shape of the solution.
- **[docs/v1-scope.md](docs/v1-scope.md)** — what is in and out of scope for v1,
  and the boundaries of this specification.
- **[docs/ADR.md](docs/ADR.md)** — all 11 architecture decision records,
  including the full ADR-005 → ADR-009 → ADR-011 amendment chain.
- **[docs/backstory.md](docs/backstory.md)** — how the project arrived at its
  name and framing; referenced from §1 of the technical whitepaper.
- **[docs/grounded-rag-v1-beads-spec.md](docs/grounded-rag-v1-beads-spec.md)** — the
  v1 work-breakdown specification: the architecture decomposed into tracked,
  dependency-ordered work items with explicit gates.
- **[docs/whitepapers/grounded-rag-v1-technical.md](docs/whitepapers/grounded-rag-v1-technical.md)**
  — the technical whitepaper: formal definitions, the Dempster-Shafer
  combination rules, the bitemporal identity tuple, the core invariants, the
  22-reference collection, and the open architectural questions.
- **[docs/whitepapers/grounded-rag-v1-marketing.md](docs/whitepapers/grounded-rag-v1-marketing.md)**
  — the companion overview paper: the same architecture told as a narrative,
  for readers who want the shape before the formalism.
- **[docs/research/active-epistemic-implementation-guide.md](docs/research/active-epistemic-implementation-guide.md)**
  — a guide to the active-epistemic learning approach behind gap detection.
- **[docs/research/epistemic-active-learning-research-synthesis.md](docs/research/epistemic-active-learning-research-synthesis.md)**
  — the research synthesis on epistemic active learning.
- **[docs/research/temporal-provenance-research-synthesis.md](docs/research/temporal-provenance-research-synthesis.md)**
  — the research synthesis behind the bitemporal and provenance models.

A good reading order: `proposal.md` → `constitution.md` → `v1-scope.md` →
`whitepapers/grounded-rag-v1-technical.md` → `ADR.md`.

---

## Sister Specification: AI Provenance Spec

Grounded RAG has a paired specification repository, **`ai-provenance-spec`**, published
alongside it. The two systems divide cleanly:

> **Grounded RAG answers from evidence. AI Provenance Spec deploys, attests, and
> revokes.**

Grounded RAG produces a well-formed answering skill; AI Provenance Spec is the
deployment substrate that packages it, validates it, attests it, admits it to
run, and can revoke it. The technical whitepaper references the AI Provenance Spec
specification where the two architectures meet — most directly at the
governance boundary, where a skill must clear admission before it can serve.

---

## Who This Specification Is For

This repository is **design-phase methodology documentation**. It is written to
be read by four roles, each of whom should find what they need to evaluate it:

- **Technical Program Management** — the axis decomposition (three layers, three
  states, two time axes) and the ADR amendment discipline show a design that
  was decomposed deliberately and amended on the record.
- **Mission Autonomy — Plans & Bands** — the `constitution.md` objective
  hierarchy and the core invariants define exactly what the system must always
  do and never do.
- **Staff Software Systems & Safety** — the `ProvenanceLedger`, the three-state
  circuit breakers, and the fail-closed Boring Mode are the operational-safety
  surface: how the system behaves when something goes wrong.
- **Director of Safety** — the standards-alignment mapping (FAA AI CSTA Issue
  Paper, NIST AI 600-1 confabulation evidence, DoD RAI Tenet 4) shows the
  architecture was designed toward recognized assurance frameworks, not in
  isolation.

The architecture is one specification; these are four lenses onto the same
design.

---

### For agents

Agents reading this repo should start at [AGENTS.md](AGENTS.md), not this README.
Claude Code users: see [CLAUDE.md](CLAUDE.md), which imports `AGENTS.md`. The
agent files document the conventions, vocabulary, and contribution discipline
agents are expected to follow.

---

## License and Attribution

- **Author:** Jonathan A. Bowe
- **License:** [Apache-2.0](LICENSE) — Apache License, Version 2.0. You may
  use, share, and adapt this material, including for commercial purposes, under
  the terms of that license; a `NOTICE` file accompanies it.

This is a design-phase architecture specification. It describes a system that
has not yet been built; read every performance figure as a target to be tested,
never as a result that has been measured.
