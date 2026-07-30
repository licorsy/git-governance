#!/usr/bin/env bash
# Configures real GitHub enforcement for the branch/merge governance rules
# in agents/git-governance-advisor.md: no direct push, no force-push, no
# deletion on protected branches. Idempotent — safe to re-run.
#
# What this DOES enforce, server-side, for every actor (human or AI agent
# using the owner's own credentials): protected branches require a pull
# request to update, reject force-pushes, and cannot be deleted.
#
# What this does NOT enforce: "only the human owner may merge into hom/main,
# not an AI agent acting as the owner." GitHub's ACLs cannot tell those two
# apart when they share one account/token — that gate is a *behavioral* rule
# in the agent persona (ask before touching hom/main), not a server-side one.
#
# Usage: setup-branch-protection.sh <owner>/<repo> [branch ...]
#   Default branches if none given: develop hom main
#   Branches that don't exist in the repo are skipped, not created.
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <owner>/<repo> [branch ...]" >&2
  echo "  Default branches if none given: develop hom main" >&2
  exit 1
fi

REPO="$1"
shift
BRANCHES=("$@")
if [ "${#BRANCHES[@]}" -eq 0 ]; then
  BRANCHES=(develop hom main)
fi

command -v gh >/dev/null 2>&1 || { echo "gh CLI is required." >&2; exit 1; }
gh auth status >/dev/null 2>&1 || {
  echo "gh CLI is not authenticated. Run 'gh auth login' first." >&2
  exit 1
}

echo "Enabling delete_branch_on_merge on ${REPO}..."
gh api --method PATCH "repos/${REPO}" -f delete_branch_on_merge=true >/dev/null

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
        "required_review_thread_resolution": false
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

echo ""
echo "Configured: ${CONFIGURED[*]:-none}. Skipped (branch not found): ${SKIPPED[*]:-none}."
