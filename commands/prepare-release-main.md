---
description: Run the promotion checklist for hom -> main and open a PR — always stops for explicit human confirmation before opening it, and never merges automatically.
---

Prepare the promotion of `hom` into `main`. This touches the most sensitive protected branch per `agents/git-governance-advisor.md` — **never** open the PR or merge without explicit confirmation, even if requested by the repo owner in the same breath as this command.

1. Fetch and check whether `hom` is up to date with `origin/hom` and whether it's ahead of `main` (`git log main..hom --oneline`). If there's nothing to release, say so and stop.
2. Check for any open PRs already targeting `main` (`gh pr list --base main`) — if one exists, report it instead of opening a duplicate.
3. Report a checklist: commits being released, whether the remote `pr-checks.yml` workflow passed on the `hom` PR (check via `gh pr checks` on the develop->hom PR if findable, otherwise note it can't be confirmed automatically), whether `main` is protected (per `/git-check`).
4. **Stop here and explicitly ask**: "Open a PR to release hom into main? (yes/no)". Do not proceed past this point without an explicit yes in this same conversation.
5. Only after explicit confirmation: `gh pr create --base main --head hom --fill`.
6. Report the PR URL and state clearly that merging is a manual, human action from here — this command does not run `gh pr merge` for `main`, regardless of confirmation. Optionally note that Conventional Commits history makes this a good point to draft release notes, but don't generate them unless asked.
