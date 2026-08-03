---
description: Promote develop -> staging -> main in one authorized window — asks once for the whole chain, then runs both hops, each only on green checks, and cuts the release tag if the repo is tag-consumed.
---

Run a **promotion window**: both hops of `develop -> staging -> main`, authorized by a single explicit confirmation instead of one per hop.

This still touches human-gated branches per `agents/git-governance-advisor.md`. What changes is the *granularity* of the confirmation, not whether one is required: nothing is opened or merged before an explicit yes in this same conversation, and that yes covers only the commit range it was shown. It is never inferred from a previous window, a previous session, or a general instruction to "keep promoting".

Use `/prepare-merge-staging` and `/prepare-release-main` instead when you want to stop between the hops — they open one PR and never merge. This command is the batched alternative, not a replacement.

1. Fetch. Determine both ranges: `git log staging..develop --oneline` and `git log main..staging --oneline`. If both are empty, say so and stop.
2. Check for open PRs already targeting `staging` or `main` (`gh pr list --base staging`, `gh pr list --base main`). If either exists, report it and stop — do not open a duplicate.
3. Confirm `develop` is up to date with `origin/develop`, then look for anything that reached `staging` or `main` outside the flow: `git rev-list --no-merges staging ^develop` and `git rev-list --no-merges main ^staging`. Two traps here, both hit on this command's first real runs:
   - **Do not test this as "the target has commits the source does not."** That is true after every promotion — merging a `develop -> staging` pull request creates a merge commit on `staging` that `develop` will never have, and `main` carries the same from each `staging -> main` merge. `--no-merges` is what excludes them; a plain `rev-list --count` does not.
   - **Do not stop on what this finds.** A repository that was ever promoted by squash carries a permanent non-merge commit on `staging` and `main` with no counterpart on `develop`, and no later promotion can clear it. Stopping would refuse to promote that repository forever. Report the commits in step 4's checklist instead and let the single confirmation cover them.

   So: **report, don't block.** Empty output is the clean state; anything printed is either a known squash-era artifact or genuinely new, and the human deciding step 5 is who can tell the two apart.
4. Report **one** checklist covering the whole window:
   - the commits in each range, grouped by hop;
   - whether `staging` and `main` are protected (per `/git-check`);
   - local `pre-commit` status — note that Actions doesn't run on `develop`, so this is a local signal, not a remote one;
   - anything step 3 printed, named and dated, so the human can say whether it is a known artifact or something new;
   - if the repo is tag-consumed (a version file plus a floating major tag — see step 8), the current version and the version this window would publish. **If the version file was not bumped in the range being promoted, say so here**, before asking: promoting to `main` without it is what `release-integrity` reports the next morning.
5. **Stop here and ask once**: "Promote this window — develop -> staging -> main? (yes/no)". Do not proceed past this point without an explicit yes in this same conversation. If the answer names only one hop, honor exactly that and stop after it.
6. First hop: `gh pr create --base staging --head develop --fill`, then wait for its checks (`gh pr checks --watch`). **Merge only if every required check is green**: `gh pr merge --merge`. On any failure, stop and report — do not open the second hop.
7. Second hop, only if the first merged cleanly: `gh pr create --base main --head staging --fill`, wait for checks the same way, then `gh pr merge --merge`. Same rule: first red stops the window.
8. If the repo is tag-consumed, cut the release in the same execution, not as a follow-up:
   - read the version from the repo's version file (`.claude-plugin/plugin.json`'s `.version` for a Claude Code plugin);
   - `git fetch --tags`, then tag `main` as `v<version>` and push it;
   - move the floating major tag (`v<major>`) to the same commit and force-push it — consumers pin the floating tag, so leaving it behind is what makes `main` and the tag disagree.
   - Verify with `git ls-remote --tags origin` before reporting done.
9. Report, using the agent's output format: what was promoted, both PR URLs, the tag if one was cut, and whether anything remains unpromoted.

**Never** widen the window beyond what was confirmed: no extra repository, no commits that landed on `develop` after the checklist was shown. If new commits arrived mid-window, finish the confirmed range and report the remainder rather than sweeping it in.
