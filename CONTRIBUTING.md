# Contributing to grounded-rag-spec

Thank you for helping improve the Grounded RAG architecture specification. This
repository is a **design-phase specification** — documentation, not code. There
is nothing to build or run; contributions are edits to the documents.

Both human and AI-agent contributors are welcome. Agents should also read
[AGENTS.md](AGENTS.md) and the Tier-2 guidance under
[docs/agents/](docs/agents/), which this document summarises for human readers.

## Ways to contribute

- **Report a bug** — something in the spec is wrong or self-contradictory.
- **Ask for clarification** — a part of the spec is ambiguous.
- **Propose an amendment** — a new architecture decision record (ADR) or a
  change to a v1 commitment.
- **Ask an integration question** — how to adopt or implement the spec.

Open an issue with one of the [issue forms](.github/ISSUE_TEMPLATE); each form
collects the details a maintainer needs.

## Before you open a pull request

1. **Branch from `main`.** Never commit to `main` directly, and never create a
   `master` branch.
2. **Name the branch** `<agent>/<scope>` for agent work (for example
   `claude/fix-adr-typo`) or `feat/*`, `fix/*`, `docs/*`, `chore/*` for human
   work. The full convention, including edge cases, is in
   [docs/agents/conventions.md](docs/agents/conventions.md).
3. **Write Conventional Commits.** `<type>(<scope>): <subject>` — imperative
   mood, subject ≤ 50 characters. Types: `feat`, `fix`, `docs`, `refactor`,
   `chore`. Commit messages are linted in CI; the build fails on a
   non-conforming message.
4. **Run the checks locally.** Install the git hooks once with `lefthook
   install`; they run the structural and sanitization checks before each
   commit. You can also run them directly:

   ```sh
   bash scripts/check-structure.sh
   bash scripts/check-sanitization.sh
   npx markdownlint-cli2 "**/*.md"
   ```

## Pull request checklist

- [ ] The branch is not `main` and follows the naming convention.
- [ ] Commit messages follow Conventional Commits.
- [ ] `scripts/check-structure.sh` and `scripts/check-sanitization.sh` pass.
- [ ] `markdownlint-cli2` reports no new violations.
- [ ] The PR description states what changed, how it was verified, and the
      semver classification below.

## Semver policy

The repository release version (`MAJOR.MINOR.PATCH`) is independent of the
specification's own version (`v1`). Classify every change:

- **major** — breaks a v1 architectural commitment.
- **minor** — a new ADR, a new section, or another additive change.
- **patch** — a correction, a clarification, or an editorial fix.

## Amending architecture decisions

The architecture decision records in [docs/ADR.md](docs/ADR.md) are an audit
trail. **Never rewrite a decided ADR in place.** To change a decision, add a new
ADR that supersedes the old one and mark the old one `Superseded by ADR-NNN`.
The worked example is the ADR-005 → ADR-009 → ADR-011 chain; see
[docs/agents/conventions.md](docs/agents/conventions.md) and
[docs/agents/glossary.md](docs/agents/glossary.md).

## Citing the specification

To cite Grounded RAG v1 in external work, see
[docs/agents/citation.md](docs/agents/citation.md) and the root `CITATION.cff`.

## License

By contributing, you agree that your contributions are licensed under the
[Apache License, Version 2.0](LICENSE) — the license of this repository.

## Security

To report a specification defect with security or privacy implications, follow
[SECURITY.md](SECURITY.md); do not open a public issue.
