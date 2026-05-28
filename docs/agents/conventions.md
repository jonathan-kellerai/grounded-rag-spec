# Conventions — grounded-rag-spec

Tier-2 detail for the conventions summarized in [AGENTS.md](../../AGENTS.md).
This file is the canonical source: if a convention changes, change it here
first, then propagate to `AGENTS.md` and any other affected document.

## Conventional Commits

Every commit message follows the [Conventional Commits 1.0.0](https://www.conventionalcommits.org)
format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

- **type** — required. One of:
  - `feat` — a new section, document, or substantive addition to the spec.
  - `fix` — a correction to an error in the spec (wrong figure, broken link,
    factual mistake).
  - `docs` — changes to `README.md`, the agent files, or other meta-docs.
  - `refactor` — restructuring that does not change the spec's meaning.
  - `chore` — repo plumbing: CI, `.gitignore`, templates, config.
- **scope** — optional. The area touched, e.g. `(adr)`, `(whitepaper)`,
  `(glossary)`, `(agents)`.
- **subject** — required. Imperative mood ("add", not "added"), ≤50 characters,
  no trailing period.
- **body** — optional. Wrapped at 72 characters. Explains the *why*.
- **footer** — optional. Use `BREAKING CHANGE:` for an amendment that supersedes
  an ADR.

### Examples

```
docs(agents): add glossary entry for Boring Mode
fix(whitepaper): correct citation count in references
feat(adr): record ADR-012 for synthesis-model resolution
chore: add markdown-lint workflow
```

## Branch naming

Agent work goes on `<agent>/<scope>` branches:

- `claude/fix-typo-adr-007`
- `codex/clarify-bel-pl-interval`
- `human/<scope>` for human contributors.

Never commit directly to `main`. Never create a `master` branch — `main` is the
only long-lived branch.

## Pull requests

- Edits to publishable files (`docs/**`, `README.md`, `AGENTS.md`, `CLAUDE.md`)
  require a PR. Staging files (anything `.gitignore`'d) may be edited directly.
- A PR description states what changed and how it was verified.
- A PR that touches an ADR must say which ADRs it touches and whether it
  supersedes one.

## Branch and commit edge cases

These cases follow from the conventions above but are easy to get wrong.

- **You are on `main`.** Stop; create a branch before committing. Never commit
  to `main` directly. Never commit from a detached HEAD — name a branch first.
- **Always base off `main`.** Branch from an up-to-date `main`, not from another
  feature branch — unless you are deliberately continuing that exact work.
- **Continuing another agent's branch.** Allowed; keep the original branch
  name, do not rename it.
- **Multi-scope changes.** If a change spans areas, omit the scope (`docs: …`)
  rather than inventing a compound one; prefer splitting unrelated changes.
- **Scope casing.** Scopes are lower-case kebab-case — `(adr)`, `(beads-spec)`,
  `(agents)`. No spaces, no camelCase.
- **Reverts.** Use the `revert` type, with the reverted commit's hash in the
  body.
- **Hotfixes.** A hotfix is still a `fix/*` (human) or `<agent>/fix-*` (agent)
  branch off `main`. There is no separate `hotfix/` prefix.
- **Worktrees.** Fine for parallel work; each worktree uses its own correctly
  named branch off `main`.
- **Fork vs same-repo PRs.** Either is accepted. Always open the PR from a
  named branch into `main` — never from a fork's `main`.
- **Commit type for plumbing.** `chore` for CI, `.gitignore`, hooks, and
  templates; `docs` for `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, the
  agent files, and anything under `docs/`.
- **Subject line.** Imperative mood, no trailing period, ≤ 50 characters.
- **Commit body.** Optional; wrap at 72 characters; explain *why*, not *what*.

## Citations

- **Internal references** — cite as `file:line` or `file:line-range`, e.g.
  `docs/ADR.md:298` or `docs/constitution.md:79-110`. This matches the citation
  style already used throughout the technical whitepaper.
- **External academic work** — cite with a full bibliographic entry: authors,
  title, venue or arXiv id, year. Match the format of the whitepaper's
  References section.
- Never write an unsourced factual claim. Cite the absence of a thing as
  carefully as its presence.

## ADR supersession discipline

The architecture decision records in `docs/ADR.md` form an audit trail. That
trail is only trustworthy if it is never silently rewritten.

- **Never edit a decided ADR's decision in place.** If a decision changes, add a
  new ADR that supersedes the old one.
- Mark the superseded ADR's status as `Superseded by ADR-NNN` — do not delete
  its text. The reasoning that was later overturned is part of the record.
- The existing chain is the model: **ADR-005 → ADR-009 → ADR-011** (see
  [glossary.md](glossary.md)). ADR-005 was superseded by ADR-009; ADR-011 then
  amended the constitution itself.
- A commit that supersedes an ADR uses a `feat(adr):` type and names the
  superseded ADR in the body.
