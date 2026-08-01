---
description: Validate the current work branch and merge it into develop, autonomously, once local checks pass.
---

Prepare and complete a merge of the current work branch into `develop`. This is the autonomous zone from `agents/git-governance-advisor.md` — no pause is needed once checks pass, but every check must actually pass first.

1. Confirm the current branch is a work branch (not `develop`/`staging`/`main` itself) and matches the taxonomy. If it doesn't match, report **Needs attention** and ask whether to proceed anyway or rename first.
2. Run `pre-commit run --all-files`. If it fails, stop, report **Blocked**, and fix or ask the user to fix the failures — do not proceed to merge with failing hooks.
3. Run `git log develop..HEAD --format=%s` and validate every subject line against Conventional Commits (`type(scope): description`, types `feat|fix|docs|refactor|chore|test|perf|build|ci`). If any commit fails, report which ones and stop — don't rewrite history without asking.
4. Push the branch: `git push -u origin HEAD`.
5. Open a PR into `develop`: `gh pr create --base develop --fill`.
6. Once the PR is open and no merge conflicts are reported, merge it: `gh pr merge --squash --delete-branch` (squash keeps `develop`'s history clean; `--delete-branch` deletes both the local and remote copies of the branch immediately, matching the lifecycle rule — don't also run `git branch -d` afterward, it will error: the branch is already gone, and even if it weren't, `-d` refuses a squash-merged branch as "not fully merged").
7. Locally: `git checkout develop && git pull --ff-only origin develop` to land on the now-updated `develop`.
8. Report the result using the agent's output format. If anything in steps 2-3 blocked the merge, this command ends there — it never merges with a failing check.
