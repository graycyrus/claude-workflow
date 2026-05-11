---
name: brb-raise-pr
description: Commit changes, merge the default branch, push, and create a draft PR. Handles conflict resolution and proper PR formatting.
allowed-tools: Bash(git *) Bash(gh *) Bash(pnpm *) Bash(npm *) Bash(yarn *) Bash(bun *) Bash(cargo *)
argument-hint: "[issue-number]"
---

# Raise a PR

## Environment detection

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
BRANCH=$(git branch --show-current)
```

If `REPO` is empty, **STOP and ask the user** to check `gh auth login` and remotes.

---

## Step 1: Stage and commit

Show `git status` and `git diff --stat` to the user first.

Stage specific files only — **never** `git add -A` or `git add .` (can include secrets, debug artifacts, unrelated changes).

```bash
git add <specific-files>
git commit -m "type(scope): short description

Closes #N"
```

Follow conventional commit style: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`

---

## Step 2: Merge default branch

Before pushing, merge the latest default branch:

```bash
git fetch origin $DEFAULT_BRANCH
git merge origin/$DEFAULT_BRANCH
```

If conflicts:
- **Lockfiles** (Cargo.lock, pnpm-lock.yaml, yarn.lock, package-lock.json): checkout theirs and regenerate
  ```bash
  git checkout --theirs <lockfile>
  # Then: cargo check / pnpm install / yarn install / npm install
  ```
- **Source files**: manually resolve, keeping intent of both sides
- Stage resolved files, commit the merge

---

## Step 3: Push

```bash
git push -u origin $BRANCH
```

---

## Step 4: Create draft PR

**Always create as a draft.** Never open a non-draft PR.

Detect if this is a fork workflow (upstream remote exists and differs from origin):

```bash
UPSTREAM_URL=$(git remote get-url upstream 2>/dev/null || echo "")
ORIGIN_URL=$(git remote get-url origin 2>/dev/null || echo "")
```

If fork workflow, determine the upstream repo for the PR target.

```bash
gh pr create --repo $REPO --base $DEFAULT_BRANCH --draft \
  --title "type: short description" \
  --body "## Summary

- What changed and why (1-3 bullets)

## Test plan

- [x] Typecheck passes
- [x] Lint passes
- [x] Format passes
- [x] Build passes

Closes #<issue-number>"
```

### PR title guidelines
- Under 70 characters
- Conventional commit prefix
- Imperative mood: "add feature" not "added feature"

---

## Step 5: Share the PR URL

Print the PR URL so the user can see it.

Suggest running `/brb-review-cycle <pr-number>` to handle the review cycle.
