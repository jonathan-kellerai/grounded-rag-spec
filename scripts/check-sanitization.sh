#!/usr/bin/env bash
# check-sanitization.sh — fail if an internal-only term reappears in a tracked
# file. The denylist is base64-encoded so this script does not itself publish
# the strings it exists to keep out. See docs/agents/enforcement.md.
#
# Run by CI (.github/workflows/ci.yml) and the lefthook pre-commit hook.
set -euo pipefail

# Base64-encoded denylist: one POSIX extended-regex pattern per line.
DENYLIST_B64='S2VsbGVyQUkKa2VsbGVyYWktZ3JjClRydXRoLUpCVApBcmNoYW5nZWxNQ1AKbG9jYWxob3N0Ojc0MDAKVGhvdWdodEJveApbQ2Ndb25maWRlbnRpYWwKQ09ORklERU5USUFMCi9Vc2Vycy8KL2hvbWUvW2Etel0Kfi9bQS1aYS16Ll0K'

patfile="$(mktemp)"
trap 'rm -f "$patfile"' EXIT
printf '%s' "$DENYLIST_B64" | base64 --decode | grep -v '^[[:space:]]*$' > "$patfile"

# Scan the files git would publish: tracked plus not-yet-ignored new files.
# Falls back to a filesystem walk when run outside a git work tree.
list_files() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git ls-files --cached --others --exclude-standard -z
  else
    find . -type f \
      -not -path './.git/*' -not -path './.claude/*' \
      -not -path './.claude-tmp/*' -not -path './.ruff_cache/*' \
      -not -path './artifacts/*' -not -path './node_modules/*' \
      -not -name '*.pdf' -not -name 'MANIFEST.md' \
      -not -name '*-PROMPT.md' -not -name 'STAGING-NOTES.md' -print0
  fi
}

status=0
while IFS= read -r -d '' file; do
  if matches="$(grep -E -I -n -H -f "$patfile" -- "$file" 2>/dev/null)"; then
    echo "check-sanitization: FAIL — denylisted pattern matched:"
    printf '%s\n' "$matches"
    status=1
  fi
done < <(list_files)

if [ "$status" -ne 0 ]; then
  echo ""
  echo "A denylisted internal term was found in a tracked file."
  echo "Remove it before committing. See docs/agents/enforcement.md."
  exit 1
fi
echo "check-sanitization: OK — no denylisted terms in tracked files."
exit 0
