---
name: pick-issue
description: Set up a git worktree and pick a GitHub issue to work on. Handles upstream sync, issue discovery, assignment, and context loading.
allowed-tools: Bash(git *) Bash(gh *) Bash(pnpm *) Bash(npm *) Bash(yarn *) Bash(bun *)
argument-hint: "[issue-number]"
---

# Pick an Issue

## Environment detection

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
GH_USER=$(gh api user -q .login 2>/dev/null || echo "")
if [ -f bun.lockb ]; then PKG=bun; elif [ -f pnpm-lock.yaml ]; then PKG=pnpm; elif [ -f yarn.lock ]; then PKG=yarn; else PKG=npm; fi
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
UPSTREAM=$(git remote get-url upstream >/dev/null 2>&1 && echo "upstream" || echo "origin")
```

If `REPO` or `GH_USER` are empty, **STOP and ask the user** to run `gh auth login`.

---

## Step 1: Branch & worktree check

```bash
git branch --show-current
git status
git worktree list
```

Show existing worktrees. If the user wants to resume one, cd into it and skip setup.

If NOT on the default branch, **STOP and ask the user**:
- Current branch, uncommitted changes, commits ahead/behind
- Options: stash+switch, commit+switch, abandon, or continue

**Do NOT silently switch branches.**

## Step 2: Sync with upstream

```bash
git fetch $UPSTREAM
git rebase $UPSTREAM/$DEFAULT_BRANCH
git push origin $DEFAULT_BRANCH
```

If conflicts, **STOP and ask**.

## Step 3: Pick the issue

If `$ARGUMENTS` contains an issue number, use that directly:
```bash
gh issue view $ARGUMENTS --repo $REPO
```

Otherwise, ask the user:
> "Do you want to work on one of **your assigned issues**, or **pick an unassigned one**?"

### Assigned issues
```bash
gh issue list --repo $REPO --assignee $GH_USER --state open
```

### Discover unassigned
1. `gh issue list --repo $REPO --state open --assignee "" --limit 50 --json number,title,labels,assignees`
2. Filter by complexity — drop hard/large-scope items
3. Filter by description quality — drop issues with < ~2k char body
4. Filter by priority — high > medium > low > unlabeled
5. Show top candidate to user
6. User confirms → `gh issue edit <N> --repo $REPO --add-assignee $GH_USER`

## Step 4: Create worktree

```bash
MAIN_REPO=$(pwd)
WORKTREE_DIR=../$(basename $MAIN_REPO)-<issue-number>
git worktree add $WORKTREE_DIR -b <type>/short-description
cd $WORKTREE_DIR
git submodule update --init --recursive

# Copy env files from main repo if they exist
for f in .env app/.env.local; do [ -f "$MAIN_REPO/$f" ] && cp "$MAIN_REPO/$f" "$f"; done

$PKG install
```

## Step 5: Load context

```bash
[ -f CLAUDE.md ] && cat CLAUDE.md
[ -f .claude/memory.md ] && cat .claude/memory.md
git log --oneline -20
```

Read the full issue, understand acceptance criteria. If anything is unclear, **ask the user**.

## Golden rule

**When in doubt, ask.** Never assume intent, scope, or approach.
