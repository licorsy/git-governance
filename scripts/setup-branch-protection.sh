#!/usr/bin/env bash
# Configures real GitHub enforcement for the branch/merge governance rules
# in agents/git-governance-advisor.md: no direct push, no force-push, no
# deletion on protected branches. Idempotent — safe to re-run.
#
# What this DOES enforce, server-side, for every actor (human or AI agent
# using the owner's own credentials): protected branches require a pull
# request to update, reject force-pushes, and cannot be deleted.
#
# Repository-level settings it sets:
#   delete_branch_on_merge=true   work branches are cleaned up automatically
#                                 on merge. Protected branches survive this:
#                                 GitHub exempts them, and the `deletion` rule
#                                 below blocks it independently. That is what
#                                 keeps `develop` — the head branch of every
#                                 develop->staging promotion — from being
#                                 deleted when a promotion merges.
#   allow_merge_commit=true       merge commits are the default everywhere.
#   allow_squash_merge=true       allowed at repo level so the per-branch
#                                 ruleset can grant it on develop only.
#   allow_rebase_merge=false      off entirely: it offers nothing this branch
#                                 model needs and rewrites committer metadata.
#
# Merge methods are then narrowed PER BRANCH via the ruleset's
# `allowed_merge_methods`, which is why this script writes one ruleset per
# branch rather than one spanning all three — a single ruleset cannot give
# develop and staging/main different methods:
#
#   develop          merge, squash
#   staging, main    merge only
#
# Promotions must never be squashed. Squashing develop->staging rewrites the
# promoted commits into a new one, so staging stops sharing history with
# develop and the NEXT promotion re-conflicts on work already merged.
#
# What this does NOT enforce: "only the human owner may merge into staging/main,
# not an AI agent acting as the owner." GitHub's ACLs cannot tell those two
# apart when they share one account/token — that gate is a *behavioral* rule
# in the agent persona (ask before touching staging/main), not a server-side one.
# Requiring an approving review does not substitute for it: GitHub forbids
# approving your own pull request, so a non-zero count locks a solo maintainer
# out of their own promotion branches. Do not "harden" it that way.
#
# Legacy rulesets: repositories protected before this script existed may carry
# a single ruleset named `branch-protection` spanning all three refs. It is
# removed when found, after the per-branch rulesets are in place — leaving both
# means two rulesets fight over allowed_merge_methods, and GitHub applies the
# intersection.
#
# Usage: setup-branch-protection.sh <owner>/<repo> [branch ...]
#   Default branches if none given: develop staging main
#   Branches that don't exist in the repo are skipped, not created.
set -euo pipefail

# The ruleset a repository may carry from before per-branch rulesets existed.
LEGACY_RULESET_NAME="branch-protection"

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <owner>/<repo> [branch ...]" >&2
  echo "  Default branches if none given: develop staging main" >&2
  exit 1
fi

REPO="$1"
shift
BRANCHES=("$@")
if [ "${#BRANCHES[@]}" -eq 0 ]; then
  BRANCHES=(develop staging main)
fi

command -v gh >/dev/null 2>&1 || { echo "gh CLI is required." >&2; exit 1; }
gh auth status >/dev/null 2>&1 || {
  echo "gh CLI is not authenticated. Run 'gh auth login' first." >&2
  exit 1
}

echo "Applying repository-level merge settings on ${REPO}..."
gh api --method PATCH "repos/${REPO}" \
  -F delete_branch_on_merge=true \
  -F allow_merge_commit=true \
  -F allow_squash_merge=true \
  -F allow_rebase_merge=false >/dev/null

EXISTING_BRANCHES="$(gh api "repos/${REPO}/branches" --jq '.[].name')"

CONFIGURED=()
SKIPPED=()

for BRANCH in "${BRANCHES[@]}"; do
  if ! grep -qx "$BRANCH" <<<"$EXISTING_BRANCHES"; then
    echo "Skipping '${BRANCH}' — does not exist in ${REPO} yet."
    SKIPPED+=("$BRANCH")
    continue
  fi

  RULESET_NAME="protect-${BRANCH}"
  EXISTING_ID="$(gh api "repos/${REPO}/rulesets" --jq ".[] | select(.name==\"${RULESET_NAME}\") | .id" 2>/dev/null || true)"

  # develop is the integration branch: squash is a useful way to collapse a
  # noisy work branch. staging and main only ever receive promotions, and a
  # squashed promotion is what forks them off develop — see the header.
  if [ "$BRANCH" = "develop" ]; then
    MERGE_METHODS='["merge", "squash"]'
  else
    MERGE_METHODS='["merge"]'
  fi

  PAYLOAD=$(cat <<JSON
{
  "name": "${RULESET_NAME}",
  "target": "branch",
  "enforcement": "active",
  "bypass_actors": [],
  "conditions": {
    "ref_name": { "include": ["refs/heads/${BRANCH}"], "exclude": [] }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" },
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "allowed_merge_methods": ${MERGE_METHODS}
      }
    }
  ]
}
JSON
)

  if [ -n "$EXISTING_ID" ]; then
    echo "Updating existing ruleset '${RULESET_NAME}' (id ${EXISTING_ID}) on ${REPO}..."
    gh api --method PUT "repos/${REPO}/rulesets/${EXISTING_ID}" --input - <<<"$PAYLOAD" >/dev/null
  else
    echo "Creating ruleset '${RULESET_NAME}' on ${REPO}..."
    gh api --method POST "repos/${REPO}/rulesets" --input - <<<"$PAYLOAD" >/dev/null
  fi
  CONFIGURED+=("$BRANCH")
done

# Only after the per-branch rulesets exist, so protection is never dropped
# even for a moment. Skipped entirely if nothing was configured — otherwise a
# run against a repo with no matching branches would strip the legacy ruleset
# and leave the repo unprotected.
LEGACY_REMOVED="none"
if [ "${#CONFIGURED[@]}" -gt 0 ]; then
  LEGACY_ID="$(gh api "repos/${REPO}/rulesets" --jq ".[] | select(.name==\"${LEGACY_RULESET_NAME}\") | .id" 2>/dev/null || true)"
  if [ -n "$LEGACY_ID" ]; then
    echo "Removing legacy ruleset '${LEGACY_RULESET_NAME}' (id ${LEGACY_ID}) — superseded by the per-branch rulesets above..."
    gh api --method DELETE "repos/${REPO}/rulesets/${LEGACY_ID}" >/dev/null
    LEGACY_REMOVED="$LEGACY_RULESET_NAME"
  fi
fi

echo ""
echo "Configured: ${CONFIGURED[*]:-none}. Skipped (branch not found): ${SKIPPED[*]:-none}. Legacy ruleset removed: ${LEGACY_REMOVED}."
