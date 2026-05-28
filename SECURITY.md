# Security Policy

## Scope

Grounded RAG is a **design-phase architecture specification** — documentation,
not running software. This policy therefore covers a specific class of issue:
a **defect in the specification itself** that, if implemented faithfully as
written, could cause a security or privacy problem in a system built from it.

Examples:

- A data structure described in the spec that would store or expose personal
  or otherwise sensitive information without the protection it should have.
- An evidence, provenance, or logging mechanism that, as specified, would
  retain content that ought to be redacted, hashed, or access-controlled.
- A control-flow or policy gate whose specified behaviour could be bypassed.

This policy covers **this repository only** — the specification. It does not
cover downstream systems that implement Grounded RAG; those are the
responsibility of their own maintainers.

## Reporting

Report a suspected specification security defect privately through
**GitHub Security Advisories** for this repository: open the **Security** tab
and use the **"Report a vulnerability"** button.

Please do not open a public issue for a security-relevant specification defect
until it has been triaged.

## What to expect

This is a documentation repository maintained on a best-effort basis, so there
is no formal response-time commitment. Triaged and accepted defects are
addressed through the normal amendment process — a new or amended architecture
decision record; see `docs/agents/conventions.md`.
