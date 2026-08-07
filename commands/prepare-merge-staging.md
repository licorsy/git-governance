---
description: Run the promotion checklist for develop -> staging and open a PR — opens without asking first, and never merges automatically.
---

Prepare the promotion of `develop` into `staging`. This touches a human-gated branch per `agents/git-governance-advisor.md`: opening the PR needs no confirmation, but **never** merge it — that step is always a manual, human action, even if requested by the repo owner in the same breath as this command.

1. Fetch and check whether `develop` is up to date with `origin/develop` and whether it's ahead of `staging` (`git log staging..develop --oneline`). If there's nothing to promote, say so and stop.
2. Check for any open PRs already targeting `staging` (`gh pr list --base staging`) — if one exists, report it instead of opening a duplicate.
3. Report a checklist: is `develop` clean of known-failing checks (best effort — note that Actions doesn't run on `develop`, so this is based on local `pre-commit` status only, not a remote signal), is `staging` protected (per `/git-check`), what commits would be promoted.
4. Open it: `gh pr create --base staging --head develop --fill`. No stop-and-ask before this step — the checklist above is the diligence, not a permission gate.
5. Report the PR URL and state clearly that merging is a manual, human action from here — this command does not run `gh pr merge` for `staging`, under any instruction.

To promote both hops on a single confirmation instead of stopping here, use `/promote-window`. It asks once for the whole chain and merges within that authorization; this command deliberately does not merge either hop, only opens this one.
