---
description: Run the promotion checklist for staging -> main and open a PR — opens without asking first, and never merges automatically.
---

Prepare the promotion of `staging` into `main`. This touches the most sensitive protected branch per `agents/git-governance-advisor.md`: opening the PR needs no confirmation, but do not merge it here — merging needs the human's explicit confirmation of this PR after it exists, and a request in the same breath as this command does not count.

1. Fetch and check whether `staging` is up to date with `origin/staging` and whether it's ahead of `main` (`git log main..staging --oneline`). If there's nothing to release, say so and stop.
2. Check for any open PRs already targeting `main` (`gh pr list --base main`) — if one exists, report it instead of opening a duplicate.
3. Report a checklist: commits being released, whether the remote `pr-checks.yml` workflow passed on the `staging` PR (check via `gh pr checks` on the develop->staging PR if findable, otherwise note it can't be confirmed automatically), whether `main` is protected (per `/git-check`).
4. Open it: `gh pr create --base main --head staging --fill`. No stop-and-ask before this step — the checklist above is the diligence, not a permission gate.
5. Report the PR URL and state clearly that merging waits for the human's explicit confirmation of this PR — this command never runs `gh pr merge` for `main` itself; after a later explicit confirmation, the agent may. Optionally note that Conventional Commits history makes this a good point to draft release notes, but don't generate them unless asked.
6. If the repo is tag-consumed (consumers pin a floating major tag, with or without a version file — see `/promote-window` step 4), say so and state that the tag has **not** been cut yet. `main` moving without its tag is what `release-integrity` reports the next morning. This command stops at the PR: once the human has merged it, cutting the tag is a follow-up action the agent may still take without a separate confirmation, because the merge itself is what triggers it, not a fresh permission event — see `agents/git-governance-advisor.md`. `/promote-window` is the path that does the whole chain, merge and tag included, in one execution.
