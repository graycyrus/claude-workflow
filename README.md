# claude-workflow

A battle-tested, AI-assisted development workflow for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Pick up a GitHub issue, plan it, implement it, ship a PR — all with structured agent orchestration.

This workflow has been refined over months of daily use on a production codebase. It works with **any project** — TypeScript, Rust, Python, Go, or anything else.

## What is this?

A set of Claude Code **skills** (slash commands) that give Claude a structured process for working through GitHub issues:

### Workflow skills

| Skill | What it does |
|---|---|
| `/brb-workflow` | Full orchestrator — issue to merged PR |
| `/brb-pick-issue` | Set up a git worktree and discover/assign a GitHub issue |
| `/brb-implement` | Plan with architectobot, implement with codecrusher, verify |
| `/brb-cross-check` | Auto-detect and run all quality checks (typecheck, lint, format, build) |
| `/brb-raise-pr` | Commit, merge main, push, create a draft PR |
| `/brb-review-cycle` | Autonomous loop: fix review comments, CI failures, merge conflicts |

### Agent skills (used by the workflow, also usable standalone)

| Skill | What it does |
|---|---|
| `/brb-architectobot` | Analyze codebase, create implementation plans, verify acceptance criteria |
| `/brb-codecrusher` | Execute implementation plans — write clean, production-ready code |
| `/brb-memory-keeper` | Capture learnings and gotchas into project memory for future sessions |
| `/brb-update-workflow` | Pull latest skills from GitHub and update your install |

## Philosophy

- **Always ask before assuming.** Plans require explicit user approval. Ambiguity gets clarified, not guessed at.
- **Git worktrees over branches.** Work on multiple issues in parallel without stashing or switching.
- **Draft PRs always.** Never open a non-draft PR. Let CI and reviewers do their thing first.
- **Autonomous review cycles.** Once a PR is up, the review cycle runs until it's fully clean — no hand-holding.
- **Zero config.** Skills auto-detect your repo, username, package manager, and default branch. No config files needed.

## Install

### Option A: Interactive installer

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/graycyrus/claude-workflow/main/install.sh)
```

Choose between:
1. **Copy — Global** (`~/.claude/skills/`) — works everywhere, update via `/brb-update-workflow`
2. **Copy — Project** (`.claude/skills/`) — per-project, update via `/brb-update-workflow`
3. **Symlink — Global** — clones to `~/.claude/claude-workflow/`, symlinks skills. `git pull` = instant updates.

### Option B: One-liner (global copy, non-interactive)

```bash
curl -fsSL https://raw.githubusercontent.com/graycyrus/claude-workflow/main/install.sh | bash
```

### Option C: Manual

```bash
git clone https://github.com/graycyrus/claude-workflow.git /tmp/claude-workflow
mkdir -p ~/.claude/skills
cp -r /tmp/claude-workflow/skills/* ~/.claude/skills/
rm -rf /tmp/claude-workflow
```

## Updating

### If you installed via copy (Options A/B/C)

Run `/brb-update-workflow` inside Claude Code — it pulls the latest from GitHub, shows what changed, and updates in place.

### If you installed via symlink (Option A, choice 3)

```bash
cd ~/.claude/claude-workflow && git pull
```

That's it — symlinks point to the repo, so changes are picked up immediately.

## Usage

Once installed, the skills are available as slash commands in Claude Code:

```
# Full workflow — start to finish
/brb-workflow

# Full workflow for a specific issue
/brb-workflow 123

# Individual steps
/brb-pick-issue
/brb-implement 123
/brb-cross-check
/brb-raise-pr 123
/brb-review-cycle 456
```

### Typical session

```
You: /brb-workflow
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

- **`/brb-architectobot`** — Explores the codebase, creates implementation plans, verifies acceptance criteria
- **`/brb-codecrusher`** — Writes code changes following the approved plan
- **`/brb-memory-keeper`** — Captures learnings and gotchas for future sessions

These ship as part of this repo. The workflow skills (`/brb-workflow`, `/brb-implement`) call them automatically, but you can also use them standalone — e.g. `/brb-architectobot 123` to plan an issue without running the full workflow.

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
rm -rf ~/.claude/skills/{brb-workflow,brb-pick-issue,brb-implement,brb-cross-check,brb-raise-pr,brb-review-cycle,brb-architectobot,brb-codecrusher,brb-memory-keeper,brb-update-workflow}

# Per-project
rm -rf .claude/skills/{brb-workflow,brb-pick-issue,brb-implement,brb-cross-check,brb-raise-pr,brb-review-cycle,brb-architectobot,brb-codecrusher,brb-memory-keeper,brb-update-workflow}

# If symlink install, also remove the cloned repo
rm -rf ~/.claude/claude-workflow
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). PRs welcome.

## License

MIT
