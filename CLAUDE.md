---
title: "Claude Code Instructions"
doc_type: instruction
description: "Claude Code's entry point for this repository: a pointer to AGENTS.md, which is the source of truth for the branch, commit, merge, and validation policy this plugin defines and scaffolds."
status: active
version: "2.0.0"
created: 2026-07-30
updated: 2026-08-01
language: en
id: claude-instructions
owner: Alexandre Clemente
tags: [git, branching, commits, merge-policy, claude-code]
---

# CLAUDE.md

[`AGENTS.md`](AGENTS.md) is the source of truth for agent instructions in this
repository. This file exists so Claude Code loads it, and states nothing of its
own — the import below is the whole content. A second copy of the policy here is
exactly the drift this plugin exists to prevent.

Scaffolded into target repositories alongside `AGENTS.md` by
`scripts/init-governance.sh`. Reset `created`, `updated`, and `owner` to the
target's own values when you do; everything else carries over unchanged.

@AGENTS.md
