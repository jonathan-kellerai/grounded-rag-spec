# CLAUDE.md — Claude Code instructions for grounded-rag-spec

@AGENTS.md

## Claude-specific notes

The import above pulls in `AGENTS.md`, which carries the conventions, file
layout, and contribution discipline that apply to every agent. The notes below
are Claude Code specific.

- **This repo is docs-only.** There is no implementation here. Do not run
  `cargo`, `npm`, `python -m`, build tools, or test runners — there is nothing
  to build or test. Work is limited to reading and editing Markdown.

- **No issue tracker in this repo.** There is no `bd` / `.beads/` tracker and no
  `.beads/PRIME.md`. Do not invoke `bd` or look for a beads database — issue
  tracking for this spec lives in the author's separate workspace, not here.

- **Prose edits:** use the `writing-clearly-and-concisely` skill for clarity
  passes and the `human-writing` skill for tone passes on human-facing prose
  (`README.md`, the marketing whitepaper). The technical documents survived a
  five-pass adversarial critique — do not regress them without explicit user
  approval.

- **Citations:** internal references use `file:line`; external academic work
  uses a full bibliographic entry. See `docs/agents/conventions.md`.

- **Staging vs publishable boundary:** `.gitignore` is the source of truth for
  this boundary. Staging-only files — `MANIFEST.md`, `STAGING-NOTES.md`, the
  `*-PROMPT.md` files, and everything under `artifacts/` — are NOT part of the
  public repo. Never move a staging file into the publishable set without
  explicit user approval.

- **Plan mode** is appropriate for any multi-file change under `docs/**`.
