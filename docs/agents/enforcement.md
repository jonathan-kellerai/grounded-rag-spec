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

## Blast-radius pulse

The blast-radius pulse is a CI gate (`.github/workflows/blast-radius-pulse.yml`)
that reads `conformance/affects.json` and the git diff of every PR to determine
which cross-file relationships were affected. The outcome is written to
`audit/blast-radius.jsonl` by `.github/workflows/blast-radius-outcome.yml`.

### `conformance/blast_radius.rego` — package `conformance.blast_radius`

The blast-radius verdict policy is a **pure deterministic function** over
`(input.changed_files, input.json_changes, input.commit_footer_actions_done)`
and the manifest `data.blast_radius.affects` (loaded from
`conformance/affects.json`). It emits one structured `result` record per
evaluation.

**Deny families (rules that can produce a non-clear verdict):**

| Rule / surface | Trigger condition | Severity |
|----------------|------------------|----------|
| `fired` | An entry's `when_changed` glob matches a path in `input.changed_files` and the sub-target gate (if any) is open | structural — populates `fired` set |
| `errors` | A `fired` entry has `severity == "error"`, `verifiable == true`, and `owed_count > 0` | error — increments `errors` counter |
| `warnings` | A `fired` entry has `owed_count > 0` and is NOT counted as an `error` (either `severity == "warning"` or `verifiable == false`) | warning — increments `warnings` counter |
| `verdict` | `"blocked"` when `errors > 0`; `"owed"` when `errors == 0` and `warnings > 0`; `"clear"` otherwise | gate result |
| `allow` | `false` when `verdict == "blocked"`, `true` otherwise | convenience boolean |

**Scope:** grounded-rag-spec only. Consumer repos invoke the policy via the
reusable workflow at a pinned SHA; they do not vendor `blast_radius.rego`.

The companion test suite is `conformance/blast_radius_test.rego`
(package `conformance.blast_radius_test`). Run `opa test conformance/` to
verify all rules are exercised.

### `conformance/affects.json` — `BR-011-affects-manifest` entry

The `BR-011-affects-manifest` entry guards the affects manifest itself.
Its `when_changed` is `conformance/affects.json`; its `severity` is `"error"`
and `verifiable` is `true`, so any edit to `conformance/affects.json` that
does not carry both discharge footers in the commit message **blocks CI**.

**Required actions (both must appear as `Pulse-Action: <id> DONE` footers):**

1. `BR-011-affects-manifest-1` — for each new or renamed manifest entry, add a
   positive test (entry fires) and a cleared test (all actions done → verdict
   clear) in `conformance/blast_radius_test.rego`.
2. `BR-011-affects-manifest-2` — document the new or changed entry in
   `docs/agents/enforcement.md` (this section).

**Rationale:** Every entry in `conformance/affects.json` is a load-bearing
cross-file relationship. Without a corresponding test case the determinism
property of `blast_radius.rego` is unproven for that entry, and without
documentation reviewers cannot judge whether the relationship is correctly
scoped. The `verifiable=true` flag means the pulse engine can assert that both
actions were taken before the PR is merged.
