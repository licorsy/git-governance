#!/usr/bin/env bash
# Scaffolds this plugin's governance files into a target repository:
#   AGENTS.md, CLAUDE.md, .pre-commit-config.yaml,
#   .github/workflows/pr-checks.yml, .claude/settings.json
#
# AGENTS.md carries the policy; CLAUDE.md is a thin `@AGENTS.md` import. Both
# are copied, because Claude Code loads CLAUDE.md while every other agent reads
# AGENTS.md by convention - one file cannot serve both without a second copy of
# the policy, which is the drift this plugin exists to prevent.
#
# A target that already has a full CLAUDE.md keeps it: skip-if-exists applies
# per file, so such a repo receives AGENTS.md and ends up with the policy stated
# TWICE. Migrating an existing repository means replacing its CLAUDE.md by hand;
# the script cannot tell a stale full copy from a deliberate local one.
#
# Source of truth is this plugin's own root — the files here are dogfooded
# by git-governance itself, not a separate templates/ copy, so there's
# nothing to drift out of sync. Never overwrites a file that already exists
# in the target; it warns and skips so you can merge by hand.
#
# `.claude/settings.json` declares `enabledPlugins`, so plugin availability
# belongs to the repository rather than to each developer's local config. It
# is copied like the rest, which means it names BOTH git-governance and its
# docs-governance companion — that is this plugin's dogfooded pairing, and a
# repository that wants only one should trim the copy after scaffolding. The
# skip-if-exists rule matters most here: a target that already declares its
# own plugins keeps them untouched.
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
  "AGENTS.md"
  "CLAUDE.md"
  ".pre-commit-config.yaml"
  ".github/workflows/pr-checks.yml"
  ".claude/settings.json"
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
