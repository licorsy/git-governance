---
description: Run the promotion checklist for staging -> main and open a PR — opens without asking first, and never merges automatically.
---

Prepare the promotion of `staging` into `main`. This touches the most sensitive protected branch per `agents/git-governance-advisor.md`: opening the PR needs no confirmation, but **never** merge it — that step is always a manual, human action, even if requested by the repo owner in the same breath as this command.

1. Fetch and check whether `staging` is up to date with `origin/staging` and whether it's ahead of `main` (`git log main..staging --oneline`). If there's nothing to release, say so and stop.
2. Check for any open PRs already targeting `main` (`gh pr list --base main`) — if one exists, report it instead of opening a duplicate.
3. Report a checklist: commits being released, whether the remote `pr-checks.yml` workflow passed on the `staging` PR (check via `gh pr checks` on the develop->staging PR if findable, otherwise note it can't be confirmed automatically), whether `main` is protected (per `/git-check`).
4. Open it: `gh pr create --base main --head staging --fill`. No stop-and-ask before this step — the checklist above is the diligence, not a permission gate.
5. Report the PR URL and state clearly that merging is a manual, human action from here — this command does not run `gh pr merge` for `main`, under any instruction. Optionally note that Conventional Commits history makes this a good point to draft release notes, but don't generate them unless asked.
6. If the repo is tag-consumed, say so and state that the tag has **not** been cut yet. `main` moving without its tag is what `release-integrity` reports the next morning. This command stops at the PR: once the human merges it, cutting the tag is a follow-up action the agent may still take without a separate confirmation, provided the promotion window itself was already authorized — see `agents/git-governance-advisor.md`. `/promote-window` is the path that does the whole chain, merge included, in one execution.
