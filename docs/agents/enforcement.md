# Enforcement

How the conventions in [AGENTS.md](../../AGENTS.md) and the rest of
`docs/agents/` are kept true over time. This is a process document — terse and
actionable. Tier-2 detail for AGENTS.md.

## Automated gates

| Gate | Where it runs | What it enforces |
|------|---------------|------------------|
| Structural check | `scripts/check-structure.sh` — CI and pre-commit | The publishable document set is present; the ADR log holds the v1 records; `CLAUDE.md` imports `AGENTS.md`. |
| Sanitization gate | `scripts/check-sanitization.sh` — CI and pre-commit | No denylisted internal term reappears in a tracked file. The denylist is base64-encoded so the script never republishes the terms it guards. |
| Markdown lint | `markdownlint-cli2` — CI | Markdown stays well-formed under the lenient `.markdownlint-cli2.yaml`. |
| Link check | `lychee` — CI | Internal and external links resolve. |
| Commit lint | `commitlint` — CI on `pull_request`, plus the `commit-msg` hook | Every commit message is a valid Conventional Commit; the build fails on a violation. |
| Branch tier | `.github/workflows/validate-branch-tier.yml` — CI on `pull_request` | The four-tier merge model holds: `main ← qa/**`, `qa ← dev/**`, `dev ← external/**` or a CODEOWNER branch. |
| Branch name (external) | `.github/workflows/validate-branch-name.yml` — CI on `pull_request` | `external/**` branch names match `external/<type>-<ISSUE-KEY>-<scope>-p<N>`; maintainer and agent branches are exempt. |
| Linked issue | `.github/workflows/validate-linked-issue.yml` — CI on `pull_request` | An `external/**` PR references an issue that is open and carries the `codeowner-approved` label. |

The pre-commit and `commit-msg` hooks are managed by `lefthook.yml`; a
contributor installs them once with `lefthook install`.

## The canonical document

`AGENTS.md` is the canonical statement of the conventions. When a convention
changes, change it in `AGENTS.md` first, then propagate to
`docs/agents/conventions.md`, `CONTRIBUTING.md`, `README.md`, and any affected
issue or pull-request template. A change not reflected in `AGENTS.md` is not in
effect.

## Review checklist

Every pull request is reviewed against:

- the conventions in `docs/agents/conventions.md` — branch name and commit
  format;
- the pull-request template's five sections, including the semver
  classification;
- the structural, sanitization, lint, link, and commit-lint gates passing in CI.

## Glossary cadence

`docs/agents/glossary.md` is reviewed whenever an ADR is added or amended: a new
ADR that introduces or redefines a load-bearing term must add or update the
corresponding glossary entry in the same pull request.

## Pre-publication IP-leak audit

Before any release, the documents receive a qualitative IP-leak audit — not
only the regex sanitization gate. The audit checks for internal tooling names,
internal URLs or hosts, absolute filesystem paths, contributor identity beyond
the public owner, and internal codenames. Each finding is either sanitized or
the offending file is excluded from publication.
