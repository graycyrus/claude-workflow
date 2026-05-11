---
name: brb-review-pr
description: CodeRabbit-style PR review — gates, intelligence gathering, structured review with severity-tagged findings, then optionally apply fixes with user approval.
allowed-tools: Read Write Edit Grep Glob Bash(git *) Bash(gh *) Bash(pnpm *) Bash(npm *) Bash(yarn *) Bash(bun *) Bash(cargo *) Bash(node *) Bash(go *) Bash(python *) Bash(pytest *) Agent(*)
argument-hint: "[pr-number]"
---

# PR Review

You are a CodeRabbit-style PR reviewer. Follow every step in order. Do NOT skip steps. Ask the user when instructed.

## Environment detection

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
if [ -f bun.lockb ]; then PKG=bun; elif [ -f pnpm-lock.yaml ]; then PKG=pnpm; elif [ -f yarn.lock ]; then PKG=yarn; else PKG=npm; fi
```

If `REPO` is empty, **STOP and ask the user** to run `gh auth login`.

If `$ARGUMENTS` contains a PR number, use that. Otherwise:

```bash
gh pr list --repo $REPO --state open
```

Show the list and let the user pick. Exclude drafts by default.

---

## Phase 1: Gates (BLOCKING)

These are gates. If any fails, stop and resolve before continuing.

### Gate 1: CI + merge conflicts

```bash
gh pr checks <PR> --repo $REPO
gh pr view <PR> --repo $REPO --json mergeable,mergeStateStatus
```

Classify failures:
- **PR-caused failures** (type errors, lint errors, test failures in PR files) → **HARD STOP**. Author needs to fix.
- **Infra/pre-existing failures** (flaky tests, runner timeouts, failures also on the default branch) → Note but continue.
- **Merge conflicts** → Soft block. Can still review, but note the final state may change.

### Gate 2: Unresolved review feedback

```bash
gh api repos/$REPO/pulls/<PR>/reviews
gh api repos/$REPO/pulls/<PR>/comments
```

Check for `CHANGES_REQUESTED` reviews not yet addressed, or unresolved comment threads. If found, ask the user: "There's unresolved feedback from [reviewer]. Review anyway or wait?"

### Gate 3: Read PR description + metadata

```bash
gh pr view <PR> --repo $REPO
gh pr diff <PR> --repo $REPO --stat
```

Extract and note: title, summary, test plan, linked issues, labels, author, files changed, commit count.

**Red flags**: no linked issue for a feature, no test plan, title doesn't match changes, very large diff (>500 lines), multiple unrelated changes bundled.

### Gate 4: Read linked issues

Extract issue references from the PR body (`Closes #N`, `Fixes #N`, `Resolves #N`). Read each:

```bash
gh issue view <issue-number> --repo $REPO
```

Extract acceptance criteria — these define "done". If no linked issue and it's a significant change, flag it.

### Gate 5: Three-way verification

Cross-check:
1. **Issue** — what was asked for (acceptance criteria)
2. **PR description** — what the PR claims to do
3. **Actual code** — what was implemented

Flag mismatches: PR overclaims, underclaims, or scope drift. This is **BLOCKING** if the PR claims to close an issue but clearly doesn't meet acceptance criteria.

---

## Phase 2: Intelligence gathering

These steps gather context. Their output feeds into the review.

### Step 6: Classify changes + build project checklist

Look at the diff and categorize files by area (backend, frontend, tests, CI, config, etc.).

If the project has a `CLAUDE.md`, read it and pull relevant rules for each area into a checklist. If not, use general best practices for the detected tech stack.

### Step 7: Read surrounding code

Read 2-3 sibling files in the modified modules (NOT in the diff) to understand:
- Naming conventions
- Error handling patterns
- Import patterns
- Test patterns
- Logging patterns

### Step 8: Automated review dedup

Check if automated reviewers (CodeRabbit, etc.) already posted:

```bash
gh api repos/$REPO/pulls/<PR>/reviews
gh api repos/$REPO/pulls/<PR>/comments
```

Summarize what they already flagged to avoid duplication.

### Step 9: Conditional checks

Based on what changed, run applicable checks:

**Dependencies changed** (lockfiles, package.json, Cargo.toml):
- Check for new deps: actively maintained? License compatible? Large dependency tree?

**Logic changed**:
- Are there tests for new logic? Are existing tests updated for behavior changes?
- Will the project's coverage gate pass?

**Exports/signatures changed**:
- Find all callers/importers of changed functions/types
- Are all consumers updated?

---

## Phase 3: Review

### Step 10: Produce CodeRabbit-style review

Read every changed file in full (not just hunks). Then produce a structured review:

````markdown
# PR #<N> — <title>

## Walkthrough
<2-4 sentence summary of what the PR does, approach, and overall assessment.>

## Changes

| File | Summary |
| --- | --- |
| `path/to/file` | <1-line summary> |

## Actionable comments (<count>)

### Blockers

#### 1. `path/to/file:line` — <title>
<Explanation of the issue and downstream effect.>

**Suggested change:**
```
// before
<current code>

// after
<proposed fix>
```

### Major

#### 2. `path/to/file:line` — <title>
<...>

### Minor / Refactor

#### 3. `path/to/file:line` — <title>
<...>

## Nitpicks (<count>)
- `path/to/file:line` — <one-line fix>

## Questions for the author (<count>)
- `path/to/file:line` — <question>

## Verified / looks good
- <Things explicitly checked and found correct>

---
**Reply with one of:**
- `apply all` — apply every suggestion
- `apply blockers+major` — apply only higher-severity items
- `apply 1,3,5` — apply specific numbered items
- `skip` — review only, no changes
- free-form instructions
````

**Rules for the review:**
- Every actionable comment must include a **concrete proposed fix** — code block or precise instruction. "Consider refactoring" is not a suggestion.
- Use file:line for every item.
- Don't repeat what automated reviewers already flagged.
- Don't invent issues. If the PR is clean, say so.
- If the PR is perfect, just say "LGTM, no issues found."

**STOP here and wait for user confirmation.** Do NOT edit code until the user responds.

---

### Step 11: Apply approved fixes

Once the user confirms which items to apply:

1. Re-read surrounding code before each edit (state may have drifted)
2. Make the changes
3. One logical concern per commit:
   - `fix(<area>): <what>` for bugs
   - `refactor(<area>): <what>` for non-behavior changes
   - `test(<area>): <what>` for tests
4. Skip anything the user declined

### Step 12: Run quality suite

Auto-detect and run checks:

```bash
# JS/TS
$PKG run typecheck 2>/dev/null
$PKG run lint 2>/dev/null
$PKG run format 2>/dev/null

# Rust
[ -f Cargo.toml ] && cargo fmt --all && cargo check

# Python
[ -f pyproject.toml ] && command -v ruff &>/dev/null && ruff check --fix .

# Go
[ -f go.mod ] && go vet ./...
```

Fix any issues, commit formatter output separately (`chore: apply formatting`).

### Step 13: Push and report

```bash
git push
```

Then report:

```
## PR #<N> — Review applied

### Suggestions: <total>
- Applied: <n>
- Skipped: <n>
- Questions: <n>

### Commits pushed
- <sha> fix(...): ...
- <sha> chore: apply formatting

### Quality suite
- typecheck: pass/fail
- lint: pass/fail
- tests: pass/fail
```

### Step 14: Post-review action

Ask the user:
1. **Approve** — `gh pr review <PR> --repo $REPO --approve`
2. **Request changes** — `gh pr review <PR> --repo $REPO --request-changes`
3. **Leave as-is** — move on

---

## Guardrails

- **Never apply changes before user confirms** — review is the deliverable, code changes come after sign-off
- **Never** push to the default branch, force-push, skip hooks, or amend published commits
- **Never** commit files that could contain secrets
- If the working tree is dirty at start, **STOP** — don't stash
- Keep the review honest — don't pad with invented issues
