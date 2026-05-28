# Full Workflow: Start to End

This is the complete ordered flow for picking up an issue, implementing it, and shipping a PR. This workflow is designed for AI-assisted development using Claude Code.

> **Autonomous mode:** This workflow can run fully autonomously. The agent should use its own judgment on trade-offs, pick the simpler approach, and keep moving. Interactive gates (plan approval, mark-ready, cleanup) have timeouts — if no human responds within 10 minutes, auto-approve and proceed. When invoked from a cron/background agent, skip all interactive gates entirely.

---

## Step 0: Branch & upstream check + worktree setup (MANDATORY BEFORE ANYTHING ELSE)

Before any work begins, ensure you are on the correct branch, synced with upstream, and set up a worktree for the issue.

### 0a. Check current branch & existing worktrees

```bash
git branch --show-current
git status
git worktree list
```

Show the user which worktrees exist and which branches they're on. If the user wants to resume work on an existing worktree, `cd` into it and skip to the relevant step.

If you are **NOT on the default branch**, **STOP and ask the user**. Show them:
- Current branch name
- Whether there are uncommitted/staged changes
- Number of commits ahead/behind
- Options:
  1. Stash changes + switch to default branch
  2. Commit current work + switch
  3. Abandon changes
  4. Continue working on the current branch (skip the rest of Step 0)

**Do NOT silently switch branches or proceed** — wait for explicit instruction.

### 0b. Sync with upstream

Once on the default branch, fetch upstream and rebase:

```bash
git fetch $UPSTREAM   # "upstream" if fork, "origin" otherwise
git rebase $UPSTREAM/$DEFAULT_BRANCH
git push origin $DEFAULT_BRANCH
```

If the rebase has conflicts, **STOP and ask the user** — do not auto-resolve.

### 0c. Create a worktree for the issue

Instead of branching in-place, create a **git worktree** so you can work on multiple issues in parallel without stashing or switching branches.

```bash
# Convention: ../<project>-<issue-number> with branch fix/<desc> or feat/<desc>
git worktree add ../<project>-<issue-number> -b <type>/short-description

cd ../<project>-<issue-number>

# Worktrees do NOT inherit submodules — init them explicitly
git submodule update --init --recursive

# Copy env files from main repo if needed
cp ../<project>/.env .env 2>/dev/null

# Install dependencies
<package-manager> install
```

From this point forward, **all work happens inside the worktree directory**.

### 0d. Parallel issues

To start a second issue, open a new terminal and repeat 0c with a different issue number. Each worktree is fully independent.

---

## Step 1: Pick an issue

Ask the user:

> "Do you want to work on one of **your assigned issues**, or **pick an unassigned one**?"

### Option A — Assigned issues

```bash
gh issue list --repo <owner/repo> --assignee <username> --state open
gh issue view <number> --repo <owner/repo>
```

### Option B — Discover an unassigned issue

Run the selection funnel:

1. **Fetch** all unassigned open issues
2. **Filter by complexity** — drop hard/large-scope items
3. **Filter by description quality** — drop issues with < ~2k chars body
4. **Filter by priority** — prefer high > medium > low > unlabeled
5. **Select top candidate** and show the user
6. **User confirms** — assign the issue

See: [01-picking-up-an-issue.md](01-picking-up-an-issue.md)

---

## Step 1.5: Get context

Before implementation, read project instructions and recent history:
- `CLAUDE.md` for project rules, patterns, conventions
- `.claude/memory.md` for institutional knowledge
- Recent commits (`git log --oneline -20`)

---

## Step 2: Understand with /brb-architectobot

Run `/brb-architectobot` to read the issue, explore the codebase, and produce an implementation plan. Present the plan and wait up to **10 minutes** for user approval. No response = auto-approved.

See: [02-working-on-an-issue.md](02-working-on-an-issue.md) — Phase 1 & 2

---

## Step 2.5: Deep audit (SKIP for obvious bugs)

**Skip for simple/obvious bugs** (missing fields, classifier updates, config fixes, 1-3 file changes). Only run for new features, large refactors, or changes to shared state/UI components.

When running: check for existing code, affected consumers, persistence concerns, test breakage. Use **Sonnet** to save tokens.

---

## Step 3: Implement with /brb-codecrusher

Run `/brb-codecrusher` to write the code changes per the approved plan.

See: [02-working-on-an-issue.md](02-working-on-an-issue.md) — Phase 3

---

## Step 4: Verify (cross-checks only, unless 4+ acceptance criteria)

**< 4 acceptance criteria:** skip architectobot — cross-checks in Step 5 are enough.
**4+ acceptance criteria:** re-run architectobot (**Sonnet**) to verify each criterion. Complex features have non-code requirements that automated checks miss.

---

## Step 5: Run all checks

Auto-detect and run available quality checks:
- TypeScript: typecheck, lint, format, build
- Rust: `cargo fmt --check`, `cargo check` (**NOT** `cargo build` — too slow, eats disk)
- Any project-specific checks from package.json

See: [03-cross-checking.md](03-cross-checking.md) and [04-pre-commit-checks.md](04-pre-commit-checks.md)

---

## Step 6: Update memory

Before committing, capture learnings from the session into `.claude/memory.md` (if the project uses it).

---

## Step 7: Commit

```bash
git add <specific-files>
git commit -m "type(scope): short description

Closes #N"
```

See: [04-pre-commit-checks.md](04-pre-commit-checks.md)

---

## Step 8: Merge default branch and resolve conflicts

```bash
git fetch origin <default-branch>
git merge origin/<default-branch>
```

Resolve any conflicts. For lockfiles: checkout theirs and regenerate.

---

## Step 9: Push and raise draft PR

**Always create PRs as drafts.**

```bash
git push -u origin <branch-name>
gh pr create --repo <owner/repo> --base <default-branch> --draft \
  --title "type: short description" \
  --body "..."
```

See: [05-raising-a-pr.md](05-raising-a-pr.md)

---

## Step 10: PR review cycle

After PR creation, run through **all three** sub-steps. Repeat until clean.

### 10a. Review comments
Process every comment individually. Verify, fix if valid, reply.

### 10b. CI checks
All checks must be green. Fix failures locally, commit, push.

### 10c. Merge conflicts
Resolve any conflicts with the default branch.

### Cycle rule
**Keep looping 10a -> 10b -> 10c until the PR is fully clean.** Do not stop early.

---

## Step 11: Mark ready for review (10-min timeout)

After the review cycle is complete, ask the user. **If no response within 10 minutes, auto-mark as ready.** In autonomous mode, mark ready immediately.

---

## Step 12: Worktree cleanup (ASK USER)

Ask the user whether to remove the worktree or keep it. **Never auto-remove worktrees** — always wait for explicit confirmation.

However, **after 10 minutes, automatically clean build artifacts** to free disk:

```bash
rm -rf <worktree>/target           # Rust build artifacts (5-15GB each)
rm -rf <worktree>/node_modules     # Node dependencies
rm -rf <worktree>/app/node_modules
```

This keeps the source code and git history intact but reclaims disk space immediately. The user can still review code, diffs, and branches — they just need to `cargo check` / `pnpm install` again if they want to rebuild.

---

## Quick reference

| Step | Action | Tool |
|------|--------|------|
| 0 | Worktree setup + upstream sync | git worktree, git fetch/rebase |
| 1 | Pick issue | gh issue list/view |
| 1.5 | Get context | Read CLAUDE.md, git log |
| 2 | Understand & plan | /brb-architectobot (**Sonnet**) |
| 2.5 | Deep audit (skip for obvious bugs) | Sonnet, only when needed |
| 3 | Implement | /brb-codecrusher (**Opus**) |
| 4 | Verify | Cross-checks only (+ Sonnet if 4+ acceptance criteria) |
| 5 | Run checks | /brb-cross-check |
| 6 | Update memory | /brb-memory-keeper |
| 7 | Commit | git add, git commit |
| 8 | Merge default branch | git fetch/merge |
| 9 | Push & draft PR | git push, gh pr create --draft |
| 10 | PR review cycle | comments + CI + conflicts loop |
| 11 | Mark ready (10-min timeout, auto in autonomous) | gh pr ready |
| 12 | Worktree cleanup (**ask user**, auto-clean builds after 10 min) | git worktree remove |
