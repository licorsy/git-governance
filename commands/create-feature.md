---
description: Create a new work branch from an up-to-date develop, following the git-governance branch taxonomy.
argument-hint: <short-description> [id] [prefix]
---

Create a new work branch following the taxonomy in `agents/git-governance-advisor.md`.

Arguments: `$ARGUMENTS` — a short description, optionally followed by an id (issue number or slug) and a prefix (`feat`, `fix`, `refactor`, `docs`, `chore`, `hotfix`; defaults to `feat` if not given).

1. Run `git status --short`. If there are uncommitted changes, stop and ask how to handle them (stash, commit, or abort) — don't create a branch on top of a dirty tree without asking.
2. Confirm the current branch is `develop`. If not, ask whether to switch to it (`git checkout develop`) before continuing.
3. Run `git pull --ff-only origin develop` to make sure the branch is up to date. If it fails (diverged history), stop and report — don't force anything.
4. Parse `$ARGUMENTS` into description, id, and prefix. Validate the prefix against the taxonomy (`feat`, `fix`, `refactor`, `docs`, `chore`, `hotfix`); if invalid or missing, default to `feat` and say so. Slugify the description (lowercase, hyphens).
5. Create the branch: `git checkout -b <prefix>/<id>-<slug>` (omit `<id>-` if none was given).
6. Report the branch name created and remind: small frequent commits, Conventional Commits format, and run `pre-commit` (or just commit — the hook runs automatically once installed) before every commit.
