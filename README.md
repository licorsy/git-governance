# git-governance

Portable branch/merge/commit governance for a solo maintainer working with
Claude Code: a subagent that guides and executes Git operations within a
fixed taxonomy and permission matrix, five slash commands that mechanize the
daily workflow, a local `pre-commit` config as the primary validation layer,
a minimal GitHub Actions workflow for the parts worth a remote check, and a
script that configures the part with real teeth — actual branch protection
on GitHub.

Naming and permission rules are guidance (the subagent + commands); "can't
push directly/force-push/delete `develop`/`staging`/`main`" is native GitHub
configuration (the script). See `agents/git-governance-advisor.md` for why
that split exists.

## Install into a repository

```bash
claude plugin marketplace add licorsy/git-governance
claude plugin install git-governance@git-governance
```

This makes the `git-governance-advisor` subagent and the 5 commands below
available in any Claude Code session opened in that repository.

## Branch and commit flow

```text
feature/* (also fix/, docs/, chore/, hotfix/)  ->  develop  ->  staging  ->  main
```

Branch names: `<prefix>/<id>-<short-description>`, e.g. `feat/142-oauth-login`,
`fix/checkout-timezone-bug`, `docs/readme-quota-section`.

Commit messages: [Conventional Commits](https://www.conventionalcommits.org/),
e.g. `feat(auth): add refresh-token rotation`, `fix: correct timezone offset
in checkout`. Full taxonomy and permission matrix live in
`agents/git-governance-advisor.md`.

## Local validation with pre-commit (primary gate)

```bash
pre-commit install
pre-commit install --hook-type commit-msg
```

Both are required: the first installs the file-content hooks (trailing
whitespace, end-of-file, YAML/JSON syntax, merge-conflict markers), the
second installs the Conventional Commits check, which runs at a different
git hook stage and is easy to forget. The config lives in
`.pre-commit-config.yaml` at the repo root and is stack-agnostic — add
language-specific linters yourself per repo.

## Configure real protection on GitHub

Once per repository (re-runnable, idempotent):

```bash
./scripts/setup-branch-protection.sh <owner>/<repo> [branch ...]
```

With no branch arguments, it tries `develop staging main` and silently skips any
that don't exist yet. Requires the `gh` CLI, authenticated, with admin
permission on the target repo.

What the script wires up:

- `delete_branch_on_merge` on the repo (automatic remote cleanup).
- One ruleset per existing protected branch: blocks direct push (requires a
  pull request, with 0 required approvals — built for a solo maintainer),
  blocks force-push, blocks deletion.

What the script does **not** and cannot do: distinguish "the owner clicked
merge" from "an AI agent using the owner's own credentials clicked merge."
That distinction is the subagent's job (`agents/git-governance-advisor.md`):
it asks before touching `staging`/`main`; up to `develop`, it acts on its own.

## Daily solo workflow

1. `/create-feature <description>` — branches from an up-to-date `develop`.
2. Work locally with small, frequent commits; `pre-commit` runs on every
   commit automatically once installed.
3. `/prepare-merge-develop` — validates the branch, opens a PR into
   `develop`, and merges it automatically once checks pass. No pause needed
   here; errors on `develop` are cheap to revert.
4. Periodically, when you have something worth promoting:
   `/prepare-merge-staging` — runs the checklist, then **stops and asks** before
   opening a `develop -> staging` PR. Merging is a manual click from there.
5. When `staging` is validated: `/prepare-release-main` — same pattern for
   `staging -> main`.
6. `/git-check` anytime — audits branch name, governance files, pre-commit
   installation, and branch protection status; offers to fix gaps, never
   writes without asking first.

## Available commands

| Command | What it does |
| --- | --- |
| `/git-check` | Audits the repo's governance setup and offers to scaffold missing pieces. |
| `/create-feature <description> [id] [prefix]` | Creates a correctly named branch from `develop`. |
| `/prepare-merge-develop` | Validates and auto-merges a work branch into `develop`. |
| `/prepare-merge-staging` | Opens a `develop -> staging` PR after explicit confirmation; never auto-merges. |
| `/prepare-release-main` | Opens a `staging -> main` PR after explicit confirmation; never auto-merges. |

## When to use GitHub Actions

`.github/workflows/pr-checks.yml` runs on `pull_request` into `staging` or
`main`, plus manual `workflow_dispatch` — and deliberately **not** on
`develop` or on plain `push`. `develop` merges happen often and are already
covered by the same `pre-commit` checks locally; running Actions there too
would spend quota re-checking what already passed. `staging` and `main` are
infrequent, deliberate promotion points, so that's where a remote
confirmation is worth the minutes.

## Companion plugins

`git-governance` owns branch taxonomy, commit format, and merge permissions
for a repo — not every workflow trigger. A companion plugin — e.g.
[docs-governance](https://github.com/licorsy/docs-governance) for Markdown
consistency — can plug into `pr-checks.yml` as a step (already wired in,
auto-skipped unless the repo has a `.docgov.config.js`), which is the
simplest option when no per-repo customization is needed. It may instead
bring its own `.github/workflows/*.yml` when it needs something the shared
step can't give it (for example, extra path filters), as long as that file is
narrowly path-filtered to what it actually checks **and** matches this repo's
branch scope — `pull_request: branches: [staging, main]` plus
`workflow_dispatch: {}`, no `push:` — the same convention `pr-checks.yml`
follows. Never enable both for the same check. See "Companion plugins" in
`CLAUDE.md` for the full rationale, including why each self-hosted plugin
marketplace must use its own plugin name as its marketplace name
(`git-governance@git-governance`, never a name shared with another plugin's
marketplace).

## Replicate into another repository

1. Install the plugin (see above) in the target repo's Claude Code session.
2. Run `/git-check` — it detects what's missing and, with your confirmation,
   scaffolds `CLAUDE.md`, `.pre-commit-config.yaml`, and
   `.github/workflows/pr-checks.yml` via `scripts/init-governance.sh`. An
   existing `CLAUDE.md` is never overwritten.
3. If the target repo doesn't have `develop`/`staging` yet, create them first
   (`git checkout -b develop && git push -u origin develop`, same for `staging`)
   — `setup-branch-protection.sh` silently skips branches that don't exist.
4. `pre-commit install && pre-commit install --hook-type commit-msg`.
5. `./scripts/setup-branch-protection.sh <owner>/<repo>`.
6. Review the scaffolded pre-commit hooks and add stack-specific linters by
   hand for that repo.
7. Commit the scaffolded files on `chore/init-governance` and open a PR into
   `develop`.

This plugin is designed to be replicated this way into any repository —
including `ai-assisted-sdd-template`, `personal-os`, and
`business-tech-agency`.

## Structure

- `agents/git-governance-advisor.md` — the persona: branch taxonomy,
  permission matrix, commit format, lifecycle, and validation output format.
- `commands/` — the 5 slash commands listed above.
- `scripts/setup-branch-protection.sh` — configures real enforcement on
  GitHub.
- `scripts/init-governance.sh` — scaffolds this plugin's governance files
  into a target repo.
- `CLAUDE.md` — the policy doc, dogfooded here and copied into target repos.
- `.pre-commit-config.yaml` / `.github/workflows/pr-checks.yml` — dogfooded
  here and copied into target repos as the local/remote validation layers.
