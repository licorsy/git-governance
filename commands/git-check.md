---
description: Audit the current repo's Git governance setup (branch, pre-commit, protection, governance files) and offer to fix gaps.
---

Audit this repository's Git governance setup and report the result using the standardized vocabulary from `agents/git-governance-advisor.md` (Compliant / Needs attention / Blocked). Do not write anything without asking first.

1. Run `git status --short` and `git branch --show-current`. Validate the current branch name against the taxonomy in `agents/git-governance-advisor.md` (or note that you're on `develop`/`staging`/`main`, which is fine).
2. Check whether `CLAUDE.md`, `.pre-commit-config.yaml`, and `.github/workflows/pr-checks.yml` exist at the repo root.
3. Check whether `pre-commit` is installed as a git hook: look for `.git/hooks/pre-commit` and `.git/hooks/commit-msg`. If the `pre-commit` executable itself isn't on PATH, note that too.
4. Best-effort check for GitHub branch protection: if `gh` is installed and authenticated, run `gh api repos/{owner}/{repo}/rulesets --jq '.[].name'` (derive `{owner}/{repo}` from `git remote get-url origin`) and report which of `develop`/`staging`/`main` have a `protect-<branch>` ruleset. If `gh` isn't available or isn't authenticated, skip this check and say so — don't fail the whole audit over it.
5. Report findings using the agent's output format (Operation status / Branch analysis / Permission and target validation / Action).
6. If any of the 3 governance files from step 2 are missing, ask explicitly whether to scaffold them via `${CLAUDE_PLUGIN_ROOT}/scripts/init-governance.sh "${CLAUDE_PROJECT_DIR}"`. Only run it after an explicit yes. It never overwrites files that already exist.
7. If `pre-commit` hooks aren't installed, suggest the exact commands (`pre-commit install && pre-commit install --hook-type commit-msg`) but don't run them without confirmation — they modify `.git/hooks`.
8. If branch protection is missing on any of `develop`/`staging`/`main` that exist in the repo, suggest `${CLAUDE_PLUGIN_ROOT}/scripts/setup-branch-protection.sh <owner>/<repo>` but don't run it without confirmation — it changes remote GitHub configuration.
