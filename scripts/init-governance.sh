#!/usr/bin/env bash
# Scaffolds this plugin's governance files into a target repository:
#   CLAUDE.md, .pre-commit-config.yaml, .github/workflows/pr-checks.yml
#
# Source of truth is this plugin's own root — the files here are dogfooded
# by git-governance itself, not a separate templates/ copy, so there's
# nothing to drift out of sync. Never overwrites a file that already exists
# in the target; it warns and skips so you can merge by hand.
#
# Usage: init-governance.sh [target-dir]
#   Defaults to $CLAUDE_PROJECT_DIR, then the current directory.
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${1:-${CLAUDE_PROJECT_DIR:-$(pwd)}}"

if [ ! -d "$TARGET_DIR" ]; then
  echo "Target directory does not exist: ${TARGET_DIR}" >&2
  exit 1
fi

FILES=(
  "CLAUDE.md"
  ".pre-commit-config.yaml"
  ".github/workflows/pr-checks.yml"
)

COPIED=()
SKIPPED=()

for FILE in "${FILES[@]}"; do
  SRC="${PLUGIN_ROOT}/${FILE}"
  DEST="${TARGET_DIR}/${FILE}"

  if [ ! -f "$SRC" ]; then
    echo "Source file missing from plugin, skipping: ${FILE}" >&2
    continue
  fi

  if [ -f "$DEST" ]; then
    echo "Skipping '${FILE}' — already exists at ${DEST}. Merge by hand if needed."
    SKIPPED+=("$FILE")
    continue
  fi

  mkdir -p "$(dirname "$DEST")"
  cp "$SRC" "$DEST"
  echo "Wrote ${FILE}"
  COPIED+=("$FILE")
done

echo ""
echo "Copied: ${#COPIED[@]} file(s). Skipped (already present): ${#SKIPPED[@]} file(s)."
