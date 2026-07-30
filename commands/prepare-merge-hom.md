---
description: Run the promotion checklist for develop -> hom and open a PR — always stops for explicit human confirmation before opening it, and never merges automatically.
---

Prepare the promotion of `develop` into `hom`. This touches a human-gated branch per `agents/git-governance-advisor.md` — **never** open the PR or merge without explicit confirmation, even if requested by the repo owner in the same breath as this command.

1. Fetch and check whether `develop` is up to date with `origin/develop` and whether it's ahead of `hom` (`git log hom..develop --oneline`). If there's nothing to promote, say so and stop.
2. Check for any open PRs already targeting `hom` (`gh pr list --base hom`) — if one exists, report it instead of opening a duplicate.
3. Report a checklist: is `develop` clean of known-failing checks (best effort — note that Actions doesn't run on `develop`, so this is based on local `pre-commit` status only, not a remote signal), is `hom` protected (per `/git-check`), what commits would be promoted.
4. **Stop here and explicitly ask**: "Open a PR to promote develop into hom? (yes/no)". Do not proceed past this point without an explicit yes in this same conversation.
5. Only after explicit confirmation: `gh pr create --base hom --head develop --fill`.
6. Report the PR URL and state clearly that merging is a manual, human action from here — this command does not run `gh pr merge` for `hom`, regardless of confirmation.
