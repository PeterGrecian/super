# Dev-Ops Super Project

Personal development operations repository - central context for all projects and infrastructure.

## Purpose

This repository exists to solve context loss between Claude Code sessions and provide a single source of truth for:
- Infrastructure setup and access patterns
- Project summaries and current state
- Coding patterns and preferences
- Cross-project tooling

## Using with Claude Code

When starting a Claude Code session on any project:

1. Reference relevant context files from this repo
2. Claude gets immediate understanding of infrastructure, patterns, and project state
3. Update context files at end of session while fresh

Example: "Read `infrastructure/homepi.md` and `projects/home-automation.md` before we start"

## Maintenance

- Update project context files after significant work sessions
- Keep infrastructure docs current when setup changes
- Add new patterns as they emerge
- Run `scripts/sync-contexts.sh` to pull latest from other repos

## Repository Structure

```
dev-ops/
├── README.md              # This file - overview and usage
├── infrastructure/        # Dev environment and access
│   ├── homepi.md         # Raspberry Pi via Tailscale
│   ├── tot-laptop.md     # Android laptop config
│   └── aws-setup.md      # IAM, credentials, account structure
├── projects/             # Individual project summaries
│   ├── home-automation.md
│   ├── network-monitoring.md
│   └── [others].md
├── patterns/             # Reusable approaches and preferences
│   ├── python-style.md
│   ├── bash-style.md
│   ├── terraform.md
│   └── debugging.md
└── scripts/              # Tooling
    ├── sync-contexts.sh  # Pull CONTEXT.md from other repos
    └── setup-env.sh      # Bootstrap new environment
```

## Access from Phone/Tot

Full GitHub and AWS credentials configured on:
- homepi (Raspberry Pi accessed via Tailscale)
- tot (Android laptop)

Both can push/pull this repo and access all project repositories.

## Sync Strategy

This repo should be synced frequently:
- Before starting work on any project
- After completing significant sessions
- When infrastructure changes

Consider it the "index" to all your development work.
