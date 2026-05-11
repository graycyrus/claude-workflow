---
description: Autonomous PR review cycle — process CodeRabbit/reviewer comments, fix CI failures, resolve merge conflicts. Loops until the PR is fully clean.
allowed-tools: Bash(git *) Bash(gh *) Bash(pnpm *) Bash(npm *) Bash(yarn *) Bash(cargo *) Bash(node *)
argument-hint: "<pr-number>"
---

# PR Review Cycle

You are running an autonomous PR review cycle. Loop until the PR is **fully clean**. Do NOT stop early. Do NOT ask the user whether to continue.

## Environment detection

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "UNKNOWN")
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
PR_NUMBER=$ARGUMENTS
if [ -f pnpm-lock.yaml ]; then PKG=pnpm; elif [ -f yarn.lock ]; then PKG=yarn; else PKG=npm; fi
```

If no PR number in `$ARGUMENTS`, detect from current branch:
```bash
PR_NUMBER=$(gh pr view --json number -q .number 2>/dev/null)
```

---

## The cycle: 10a -> 10b -> 10c -> repeat

### 10a. Review comments

Wait ~2 minutes for automated reviews to post, then read all comments:

```bash
# Inline comments
gh api repos/$(echo $REPO)/pulls/$PR_NUMBER/comments

# Review-level comments
gh api repos/$(echo $REPO)/pulls/$PR_NUMBER/reviews

# General PR comments
gh api repos/$(echo $REPO)/issues/$PR_NUMBER/comments
```

For **each** comment:

1. **Verify** — check whether the finding is valid against the actual code (automated reviewers can be wrong)
2. **Fix if valid** — make the change, run checks, commit, push
3. **Reply individually** — respond to the specific comment explaining what was fixed, or why no fix is needed

```bash
# Reply to an inline comment
gh api repos/$(echo $REPO)/pulls/$PR_NUMBER/comments/<comment_id>/replies \
  -X POST -f body="Fixed in $(git rev-parse --short HEAD) — description of fix"

# General PR comment
gh pr comment $PR_NUMBER --repo $REPO --body "..."
```

**Do not ignore review comments** — always respond to each one.

### 10b. CI checks

```bash
gh pr checks $PR_NUMBER --repo $REPO
```

If any check is failing:

1. **Read the log**:
   ```bash
   gh run view <run_id> --repo $REPO --log-failed
   ```
2. **Fix locally** — make the change, verify with the matching local command
3. **Commit and push** — checks will re-run automatically

Do NOT consider the PR ready until all checks are green.

### 10c. Merge conflicts

```bash
git fetch origin $DEFAULT_BRANCH
git merge origin/$DEFAULT_BRANCH
```

If conflicts:
- **Lockfiles**: checkout theirs and regenerate
- **Source files**: manually resolve
- Stage, commit, push

After pushing a merge commit, **loop back to 10b** — confirm checks still pass.

---

## Cycle exit conditions

**Keep looping until ALL of these are true:**

- [ ] Every review comment has been individually fixed or dismissed with a reply
- [ ] All CI checks are green (zero failures)
- [ ] Zero merge conflicts with the default branch
- [ ] No new review comments appeared after the latest push

If fixing one comment introduces a new failure or conflict, that's a new iteration — keep going.

---

## When clean: ask about marking ready

Once the PR is fully clean, **ask the user**:

> "Everything looks good — want me to mark the PR as ready for review?"

If yes:
```bash
gh pr ready $PR_NUMBER --repo $REPO
```

Never mark ready without explicit user approval.
