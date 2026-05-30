# AGENTS.md — Grounded RAG Spec v1 Architecture Specification

This repository is the **v1 architecture specification** for Grounded RAG, an
evidence-grounded retrieval-and-answer system. Humans read [README.md](README.md);
**agents start here.**

This file is **Tier 1** of a three-tier progressive-disclosure structure: a
lightweight overview that points at deeper Tier-2 files under `docs/agents/`.
Read this file fully before doing any work in the repo.

## What this repo is — and is not

- **It IS** a design-phase specification: prose, architecture decision records
  (ADRs), and research synthesis describing a system that has not been built.
- **It is NOT** an implementation. There is no runtime, no package, no test
  suite, and no `cargo` / `npm` / `python` project. Do not invent code paths,
  do not claim a runtime exists, and do not report benchmark numbers — every
  performance figure in the docs is a prospective target, never a measured
  result.
- **License:** Apache-2.0. All content is documentation under that license.
- **Default branch:** `main`. Never create or reference `master`.

## File layout and agent reading order

Read in this order to build context fast:

1. `docs/proposal.md` — what Grounded RAG is and why it exists.
2. `docs/constitution.md` — the non-negotiable design principles.
3. `docs/v1-scope.md` — what v1 includes and explicitly excludes.
4. `docs/whitepapers/grounded-rag-v1-technical.md` — the full technical design.
5. `docs/ADR.md` — the 11 ADRs and their amendment chain.

Other files:

- `docs/backstory.md` — narrative context for the design.
- `docs/grounded-rag-v1-beads-spec.md` — the v1 work breakdown as a tracked-issue
  spec; any issue-tracker commands shown in it are illustrative, not commands
  to run.
- `docs/whitepapers/grounded-rag-v1-marketing.md` — the non-technical overview.
- `docs/research/*.md` — three research-synthesis documents underpinning the
  design.
- `docs/agents/*.md` — Tier-2 agent guidance (see pointers below).

## Conventions agents must follow

- **Branch naming and merge tiers:** CI enforces a four-tier merge model —
  `main ← qa/** ← dev/** ← external/**` (or a CODEOWNER-owned branch into
  `dev`), checked on every pull request by
  `.github/workflows/validate-branch-tier.yml`. Agent and maintainer work goes
  on `<agent>/<scope>` branches — e.g. `claude/fix-typo-adr-007`,
  `codex/clarify-bel-pl-interval`; use `human/<scope>` for human contributors.
  Because the author is a CODEOWNER, these branches may open a PR directly into
  `dev`; promote through a `qa/**` branch to reach `main`. Outside contributors
  use `external/<type>-<ISSUE-KEY>-<scope>-p<N>` (validated by
  `validate-branch-name.yml`). Never commit directly to `main`. Full model:
  `docs/agents/conventions.md`.
- **Commits:** Conventional Commits — `<type>(<scope>): <subject>`. Subject in
  imperative mood, ≤50 characters. Types: `feat`, `fix`, `chore`, `docs`,
  `refactor`. Scope is optional. See `docs/agents/conventions.md`.
- **Edit discipline:** changes to publishable docs (`docs/**`, `README.md`,
  `AGENTS.md`, `CLAUDE.md`) require a pull request. Changes to staging files
  (anything `.gitignore`'d) may be made directly.
- **Never delete a file** without explicit user permission — including files you
  created yourself. Ask first; wait for an explicit yes.
- **ADR discipline:** never silently rewrite a decided ADR. Supersede it with a
  new ADR and record the supersession. See `docs/agents/conventions.md`.
- **Citations:** cite internal references as `file:line`; cite external academic
  work with a full bibliographic entry. See `docs/agents/conventions.md`.

## Open architectural question — surface this

The synthesis step in the live answer path has **no named generative model**.
The two models in the design (`bge-small-en-v1.5` and `ms-marco-MiniLM-L-6-v2`)
are both encoder-only and structurally cannot generate text.
[Technical Whitepaper §10.1](docs/whitepapers/grounded-rag-v1-technical.md)
("Known Architectural Gap") documents three candidate resolutions — host-LLM
delegation, a bundled local generative model, or template-only Boring Mode —
and none is confirmed. This is a constitutional-level question: it may force an
amendment to ADR-011 (runtime self-containment as a hard constraint). **Any
agent discussing the architecture must surface this gap rather than paper over
it.**

## Tier-2 pointers

When you need more than this overview, read the matching Tier-2 file:

- `docs/agents/conventions.md` — full Conventional Commits spec, branch naming,
  PR style, citation format, ADR supersession discipline.
- `docs/agents/citation.md` — how to cite Grounded RAG Spec v1 externally (Apache-2.0
  attribution template, BibTeX entry).
- `docs/agents/glossary.md` — load-bearing vocabulary: Grounded / Partial /
  Abstain, EvidenceSpan, ProvenanceLedger, BPA, `[Bel, Pl]`, Boring Mode, the
  ADR amendment chain.
- `docs/agents/enforcement.md` — how these conventions are enforced: the CI
  gates, the pre-commit hook, and the canonical-document rule.
