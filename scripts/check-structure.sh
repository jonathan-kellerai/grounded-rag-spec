#!/usr/bin/env bash
# check-structure.sh — primary artifact validation for this specification repo.
# Confirms the publishable document set is present and structurally sane.
# Run by CI (.github/workflows/ci.yml) and the lefthook pre-commit hook.
set -euo pipefail

status=0
note() { echo "check-structure: $*"; }
fail() { echo "check-structure: FAIL — $*"; status=1; }

required_files=(
  README.md
  LICENSE
  NOTICE
  AGENTS.md
  CLAUDE.md
  CONTRIBUTING.md
  docs/constitution.md
  docs/proposal.md
  docs/v1-scope.md
  docs/ADR.md
  docs/backstory.md
  docs/grounded-rag-v1-beads-spec.md
  docs/whitepapers/grounded-rag-v1-technical.md
  docs/whitepapers/grounded-rag-v1-marketing.md
  docs/research/active-epistemic-implementation-guide.md
  docs/research/epistemic-active-learning-research-synthesis.md
  docs/research/temporal-provenance-research-synthesis.md
  docs/agents/conventions.md
  docs/agents/citation.md
  docs/agents/glossary.md
  docs/agents/enforcement.md
)
for f in "${required_files[@]}"; do
  [ -f "$f" ] || fail "missing required file: $f"
done

# The ADR log must hold at least the eleven v1 records.
if [ -f docs/ADR.md ]; then
  adr_count=$(grep -c '^## ADR-' docs/ADR.md || true)
  if [ "${adr_count:-0}" -lt 11 ]; then
    fail "expected at least 11 ADRs in docs/ADR.md, found ${adr_count:-0}"
  else
    note "ADR count: $adr_count"
  fi
  for adr in 'ADR-005' 'ADR-009' 'ADR-011'; do
    grep -q "$adr" docs/ADR.md || fail "supersession-chain record $adr not found in docs/ADR.md"
  done
fi

# CLAUDE.md must import AGENTS.md so every agent toolchain reads one source.
if [ -f CLAUDE.md ]; then
  grep -q '^@AGENTS\.md' CLAUDE.md || fail "CLAUDE.md does not import AGENTS.md (expected an @AGENTS.md line)"
fi

if [ "$status" -eq 0 ]; then
  note "OK — specification structure is valid."
fi
exit "$status"
