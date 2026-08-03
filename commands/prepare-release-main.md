---
description: Run the promotion checklist for staging -> main and open a PR — always stops for explicit human confirmation before opening it, and never merges automatically.
---

Prepare the promotion of `staging` into `main`. This touches the most sensitive protected branch per `agents/git-governance-advisor.md` — **never** open the PR or merge without explicit confirmation, even if requested by the repo owner in the same breath as this command.

1. Fetch and check whether `staging` is up to date with `origin/staging` and whether it's ahead of `main` (`git log main..staging --oneline`). If there's nothing to release, say so and stop.
2. Check for any open PRs already targeting `main` (`gh pr list --base main`) — if one exists, report it instead of opening a duplicate.
3. Report a checklist: commits being released, whether the remote `pr-checks.yml` workflow passed on the `staging` PR (check via `gh pr checks` on the develop->staging PR if findable, otherwise note it can't be confirmed automatically), whether `main` is protected (per `/git-check`).
4. **Stop here and explicitly ask**: "Open a PR to release staging into main? (yes/no)". Do not proceed past this point without an explicit yes in this same conversation.
5. Only after explicit confirmation: `gh pr create --base main --head staging --fill`.
6. Report the PR URL and state clearly that merging is a manual, human action from here — this command does not run `gh pr merge` for `main`, regardless of confirmation. Optionally note that Conventional Commits history makes this a good point to draft release notes, but don't generate them unless asked.
7. If the repo is tag-consumed, say so and state that the tag has **not** been cut: `main` moving without its tag is what `release-integrity` reports the next morning. This command stops at the PR, so cutting it is the human's next step — `/promote-window` is the path that does it in the same execution.
