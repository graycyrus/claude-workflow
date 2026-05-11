# claude-workflow

A battle-tested, AI-assisted development workflow for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Pick up a GitHub issue, plan it, implement it, ship a PR — all with structured agent orchestration.

This workflow has been refined over months of daily use on a production codebase. It works with **any project** — TypeScript, Rust, Python, Go, or anything else.

## What is this?

A set of Claude Code **skills** (slash commands) that give Claude a structured process for working through GitHub issues:

### Workflow skills

| Skill | What it does |
|---|---|
| `/workflow` | Full orchestrator — issue to merged PR |
| `/pick-issue` | Set up a git worktree and discover/assign a GitHub issue |
| `/implement` | Plan with architectobot, implement with codecrusher, verify |
| `/cross-check` | Auto-detect and run all quality checks (typecheck, lint, format, build) |
| `/raise-pr` | Commit, merge main, push, create a draft PR |
| `/review-cycle` | Autonomous loop: fix review comments, CI failures, merge conflicts |

### Agent skills (used by the workflow, also usable standalone)

| Skill | What it does |
|---|---|
| `/architectobot` | Analyze codebase, create implementation plans, verify acceptance criteria |
| `/codecrusher` | Execute implementation plans — write clean, production-ready code |
| `/memory-keeper` | Capture learnings and gotchas into project memory for future sessions |

## Philosophy

- **Always ask before assuming.** Plans require explicit user approval. Ambiguity gets clarified, not guessed at.
- **Git worktrees over branches.** Work on multiple issues in parallel without stashing or switching.
- **Draft PRs always.** Never open a non-draft PR. Let CI and reviewers do their thing first.
- **Autonomous review cycles.** Once a PR is up, the review cycle runs until it's fully clean — no hand-holding.
- **Zero config.** Skills auto-detect your repo, username, package manager, and default branch. No config files needed.

## Install

### Option A: Global (all your projects)

```bash
git clone https://github.com/graycyrus/claude-workflow.git /tmp/claude-workflow
mkdir -p ~/.claude/skills
cp -r /tmp/claude-workflow/skills/* ~/.claude/skills/
rm -rf /tmp/claude-workflow
```

### Option B: Per-project

```bash
git clone https://github.com/graycyrus/claude-workflow.git /tmp/claude-workflow
mkdir -p .claude/skills
cp -r /tmp/claude-workflow/skills/* .claude/skills/
rm -rf /tmp/claude-workflow
```

### Option C: One-liner (installs globally)

```bash
curl -fsSL https://raw.githubusercontent.com/graycyrus/claude-workflow/main/install.sh | bash
```

For interactive mode (choose global vs project), download and run directly:
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/graycyrus/claude-workflow/main/install.sh)
```

## Usage

Once installed, the skills are available as slash commands in Claude Code:

```
# Full workflow — start to finish
/workflow

# Full workflow for a specific issue
/workflow 123

# Individual steps
/pick-issue
/implement 123
/cross-check
/raise-pr 123
/review-cycle 456
```

### Typical session

```
You: /workflow
Claude: [detects repo, username, package manager]
        [checks branch, syncs upstream, creates worktree]
        "Do you want to work on an assigned issue or pick an unassigned one?"
You: pick one for me
Claude: [runs discovery funnel, shows top candidate]
        "Issue #87: Add dark mode toggle — priority: medium. Go ahead?"
You: yes
Claude: [assigns issue, loads context, runs architectobot]
        [presents implementation plan]
        "Here's the plan. Any concerns before I implement?"
You: looks good, go ahead
Claude: [runs codecrusher, implements, verifies, runs checks]
        [commits, pushes, creates draft PR]
        [enters review cycle — fixes comments, CI, conflicts]
        "Everything's clean. Want me to mark the PR as ready?"
```

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI installed
- [GitHub CLI](https://cli.github.com/) (`gh`) installed and authenticated
- Git configured with your identity

## How it works

The workflow orchestrates three specialized agent skills:

- **`/architectobot`** — Explores the codebase, creates implementation plans, verifies acceptance criteria
- **`/codecrusher`** — Writes code changes following the approved plan
- **`/memory-keeper`** — Captures learnings and gotchas for future sessions

These ship as part of this repo. The workflow skills (`/workflow`, `/implement`) call them automatically, but you can also use them standalone — e.g. `/architectobot 123` to plan an issue without running the full workflow.

## Auto-detection

Skills detect your project setup at runtime — no configuration needed:

| What | How |
|---|---|
| Repo (owner/name) | `gh repo view` |
| GitHub username | `gh api user` |
| Package manager | Lockfile detection (bun/pnpm/yarn/npm) |
| Default branch | `git symbolic-ref` |
| Upstream remote | Checks for `upstream` remote |
| Available checks | Reads `package.json` scripts, checks for `Cargo.toml` |

## Docs

Detailed reference docs are in [`docs/`](docs/):

- [Full workflow](docs/00-full-workflow.md) — complete step-by-step
- [Picking up an issue](docs/01-picking-up-an-issue.md) — discovery and assignment
- [Working on an issue](docs/02-working-on-an-issue.md) — plan, implement, verify
- [Cross-checking](docs/03-cross-checking.md) — quality checks
- [Pre-commit checks](docs/04-pre-commit-checks.md) — staging and committing
- [Raising a PR](docs/05-raising-a-pr.md) — PR creation and review

## Uninstall

```bash
# Global
rm -rf ~/.claude/skills/{workflow,pick-issue,implement,cross-check,raise-pr,review-cycle,architectobot,codecrusher,memory-keeper}

# Per-project
rm -rf .claude/skills/{workflow,pick-issue,implement,cross-check,raise-pr,review-cycle,architectobot,codecrusher,memory-keeper}
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). PRs welcome.

## License

MIT
