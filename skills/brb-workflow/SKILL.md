---
name: brb-workflow
description: Full AI-assisted development workflow — from issue discovery to merged PR. Orchestrates worktree setup, planning, implementation, cross-checking, and PR review cycles.
allowed-tools: Bash(git *) Bash(gh *) Bash(pnpm *) Bash(npm *) Bash(yarn *) Bash(bun *) Bash(cargo *) Bash(node *) Agent(*)
argument-hint: "[issue-number]"
---

# Full Workflow: Start to End

You are running an AI-assisted development workflow. Follow every step in order. Do NOT skip steps. Ask the user when instructed to ask.

## Environment detection

Detect these values once and use them throughout:

```bash
# Repo (owner/repo)
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")

# GitHub username (must be the login, not display name)
GH_USER=$(gh api user -q .login 2>/dev/null || echo "")

# Package manager
if [ -f bun.lockb ]; then PKG=bun; elif [ -f pnpm-lock.yaml ]; then PKG=pnpm; elif [ -f yarn.lock ]; then PKG=yarn; else PKG=npm; fi

# Default branch
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

# Upstream remote (if fork workflow)
UPSTREAM=$(git remote get-url upstream >/dev/null 2>&1 && echo "upstream" || echo "origin")
```

Print these values so the user can confirm. If `REPO` or `GH_USER` are empty, **STOP and ask the user** — they may need to run `gh auth login` or set up the remote.

---

## Session resume (before anything else)

Check for in-progress work from a previous session:

```bash
# Existing worktrees (besides the main one)
git worktree list

# Open draft PRs by the user
gh pr list --repo $REPO --author $GH_USER --state open --draft
```

If there are active worktrees or open draft PRs, show them and ask:

> "I found in-progress work:
> - Worktree `../project-123` on branch `feat/dark-mode` (issue #123)
> - Draft PR #456: 'feat: add dark mode toggle'
>
> **Resume** one of these, or **start fresh** on a new issue?"

If the user wants to resume:
- `cd` into the worktree
- Determine the current phase:
  - Has a PR? → skip to **Step 10 (PR review cycle)**
  - Has commits but no PR? → skip to **Step 9 (Push and raise PR)**
  - Has changes but no commits? → skip to **Step 5 (Run checks)**
  - Clean worktree? → skip to **Step 2 (Plan with /brb-architectobot)**

If no in-progress work, or user wants to start fresh, continue to Step 0.

---

## Step 0: Branch & upstream check + worktree setup

### 0a. Check current state

```bash
git branch --show-current
git status
git worktree list
```

Show the user which worktrees exist. If they want to resume an existing worktree, cd into it and skip to the relevant step.

If NOT on the default branch, **STOP and ask the user**. Show:
- Current branch name
- Uncommitted/staged changes
- Commits ahead/behind default branch
- Options: stash+switch, commit+switch, abandon, or continue on current branch

**Do NOT silently switch branches.**

### 0b. Sync with upstream

```bash
git fetch $UPSTREAM
git rebase $UPSTREAM/$DEFAULT_BRANCH
git push origin $DEFAULT_BRANCH
```

If rebase has conflicts, **STOP and ask the user**.

### 0c. Create a worktree

```bash
# Save the main repo path before changing directory
MAIN_REPO=$(pwd)

# Convention: ../<repo-short>-<issue-number>
WORKTREE_DIR=../$(basename "$MAIN_REPO")-<issue-number>
git worktree add $WORKTREE_DIR -b <type>/short-description

cd $WORKTREE_DIR

# Init submodules if any
git submodule update --init --recursive

# Copy env files from main repo if they exist
for f in .env app/.env.local; do [ -f "$MAIN_REPO/$f" ] && cp "$MAIN_REPO/$f" "$f"; done

# Install dependencies
$PKG install
```

All work for this issue happens inside the worktree directory.

**Save state**: Remember the issue number, branch name, and worktree path for session resume.

---

## Step 1: Pick an issue

If `$ARGUMENTS` contains an issue number, use that. Otherwise ask the user:

> "Do you want to work on one of **your assigned issues**, or **pick an unassigned one**?"

### Option A — Assigned issues

```bash
gh issue list --repo $REPO --assignee $GH_USER --state open
gh issue view <number> --repo $REPO
```

### Option B — Discover unassigned

1. Fetch unassigned open issues:
   ```bash
   gh issue list --repo $REPO --state open --assignee "" --limit 50 --json number,title,labels,assignees
   ```
2. Filter by complexity — drop clearly hard/large-scope items. Keep easy to medium.
3. Filter by description quality — fetch body, drop issues with < ~2k chars.
4. Filter by priority — prefer `priority: high` > `medium` > `low` > unlabeled.
5. Show top candidate to user (number, title, priority, labels, first ~5 lines).
6. User confirms → assign: `gh issue edit <N> --repo $REPO --add-assignee $GH_USER`

---

## Step 1.5: Get context

Before implementation, read project instructions and recent history:

```bash
# Read project instructions if they exist
[ -f CLAUDE.md ] && cat CLAUDE.md
[ -f .claude/memory.md ] && cat .claude/memory.md

# Recent commits
git log --oneline -20
```

---

## Step 2: Understand with /brb-architectobot

Run `/brb-architectobot <issue-number>` to read the issue, explore the codebase, and produce an implementation plan.

The plan must be **explicitly approved by the user** before moving to implementation.

---

## Step 2.5: Deep audit

Before user approval, run a deep audit:

1. Does any proposed code already exist?
2. Who consumes the state/components being changed?
3. Are there existing UI patterns to reuse?
4. State persistence / migration concerns?
5. Test references that might break?
6. Side effects on mount/unmount?

Revise the plan based on findings. Present the revised plan to the user for approval.

---

## Step 3: Implement with /brb-codecrusher

Run `/brb-codecrusher` to write code per the approved plan.

---

## Step 4: Verify with /brb-architectobot

Run `/brb-architectobot <issue-number>` again, this time asking it to verify every acceptance criterion from the issue is met end-to-end.

Fix anything flagged.

---

## Step 5: Run all checks

Auto-detect and run quality checks:

```bash
# Detect available checks from package.json
node -e "const p=require('./package.json'); const s=p.scripts||{}; const checks=['typecheck','lint','format:check','build']; checks.forEach(c => { if(s[c]) console.log(c) })" 2>/dev/null

# Run each detected check with the project's package manager
$PKG run typecheck 2>/dev/null
$PKG run lint 2>/dev/null
$PKG run format:check 2>/dev/null
$PKG run build 2>/dev/null

# Rust checks if Cargo.toml exists
[ -f Cargo.toml ] && cargo fmt --all --check && cargo check
```

---

## Step 6: Update memory

Run `/brb-memory-keeper` to capture learnings from this session into the project's memory file.

---

## Step 7: Commit

```bash
git add <specific-files>
git commit -m "type(scope): short description

Closes #N"
```

Stage specific files only — never `git add -A`.

---

## Step 8: Merge default branch and resolve conflicts

```bash
git fetch origin $DEFAULT_BRANCH
git merge origin/$DEFAULT_BRANCH
```

If conflicts: resolve, stage, commit. For lockfiles: checkout theirs and regenerate.

---

## Step 9: Push and raise draft PR

**Always create PRs as drafts.**

```bash
git push -u origin <branch-name>
gh pr create --repo $REPO --base $DEFAULT_BRANCH --draft \
  --title "type: short description" \
  --body "## Summary

- Bullet point 1
- Bullet point 2

## Test plan

- [x] Typecheck passes
- [x] Lint passes
- [x] Format passes
- [x] Build passes

Closes #<issue-number>"
```

**Save state**: Remember the PR number and URL for session resume.

---

## Step 10: PR review cycle

After PR creation, run through **all three** sub-steps. Repeat until the PR is fully clean.

### 10a. Review comments

```bash
gh api repos/$REPO/pulls/<N>/comments
gh api repos/$REPO/pulls/<N>/reviews
```

For each comment: verify, fix if valid, reply individually.

### 10b. CI checks

```bash
gh pr checks <N> --repo $REPO
```

If failing: read logs, fix locally, commit, push.

### 10c. Merge conflicts

```bash
git fetch origin $DEFAULT_BRANCH
git merge origin/$DEFAULT_BRANCH
```

Resolve any conflicts, push.

### Cycle rule

**Keep looping 10a -> 10b -> 10c until ALL of these are true:**
- Every review comment fixed or dismissed with a reply
- All CI checks green
- Zero merge conflicts
- No new review comments after latest push

Do NOT stop early. Do NOT ask the user whether to continue. Run autonomously until clean.

---

## Step 11: Mark ready for review (ASK USER)

After the review cycle is complete, **ask the user**:

> "Everything looks good — want me to mark the PR as ready for review?"

If yes: `gh pr ready <N> --repo $REPO`

---

## Step 12: Worktree cleanup (ASK USER)

**Ask the user** whether to clean up:

> "Do you want me to remove the worktree, or keep it?"

If remove:
```bash
cd $MAIN_REPO
git worktree remove $WORKTREE_DIR
git branch -d <branch-name>  # use -D if the branch was not yet merged
```
