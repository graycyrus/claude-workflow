---
name: brb-create-issue
description: Turn a casual description into a well-structured GitHub issue — researches the codebase, drafts using repo templates, asks for confirmation, and files it.
allowed-tools: Read Grep Glob Bash(git *) Bash(gh *) Bash(ls *)
argument-hint: "[description of the problem or idea]"
---

# Create Issue

Turn a plain-language description into a well-structured GitHub issue. Research first, draft second, file only after user confirmation.

## Environment detection

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
GH_USER=$(gh api user -q .login 2>/dev/null || echo "")
```

If `REPO` is empty, **STOP and ask the user** to check `gh auth login` and remotes.

---

## Step 1: User describes the problem or idea

The user explains in plain language what's broken or what they want. `$ARGUMENTS` contains their description. No format required from them.

If `$ARGUMENTS` is empty, ask: "What's the issue? Describe it however you like — I'll structure it."

---

## Step 2: Research

Before drafting anything, investigate the codebase.

### For bugs

1. **Trace the code path** — find relevant files, components, state, and logic
2. **Identify root cause** — what's actually broken and why
3. **Check for related issues**:
   ```bash
   gh issue list --repo $REPO --state open --limit 50 --json number,title
   ```
4. **Note reproduction steps** — what triggers the bug
5. **Identify affected files** — list them for the issue body

### For features

1. **Understand current state** — what exists today in this area
2. **Scope the work** — what needs to be built, what can be reused
3. **Check for overlap** — existing issues, partial implementations
4. **Identify the category** — which domain/module this belongs to

### Determining bug vs feature

Decide based on context:
- **Bug** — something that should work but doesn't. Unexpected behavior, regressions, crashes.
- **Feature** — something new that doesn't exist yet. New capability, enhancement.

The user does not need to specify this. Determine from context.

### Research depth

- **Simple/obvious** — quick trace, minimal exploration
- **Complex/unclear** — deep codebase exploration, multiple files, state flow tracing
- **Ambiguous scope** — ask the user clarifying questions before drafting

---

## Step 3: Draft and confirm

### Check for issue templates

```bash
ls .github/ISSUE_TEMPLATE/ 2>/dev/null
```

If templates exist (e.g. `bug.md`, `feature.md`), read them and use their format. If not, use a sensible default structure:

**Bug format:**
```markdown
## Summary
What's broken, in one sentence.

## Problem
What happens, repro steps, expected vs actual.

## Root cause
What's wrong in the code and why.

## Proposed fix
How to fix it.

## Acceptance criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Affected files
- `path/to/file`
```

**Feature format:**
```markdown
## Summary
What's being added, in one sentence.

## Problem
What's missing or what user need isn't met.

## Proposed solution
Approach and scope.

## Acceptance criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Related
Links to related issues, docs, or code.
```

### Fill in the draft

Claude fills in every section from research findings. The user should not need to write the issue body.

### Apply labels

Determine automatically:
- Bug → `bug` label
- Feature → `enhancement` label
- Additional labels if obvious from the repo's label set

### When to ask more questions

Before presenting the draft, ask if:
- **Scope is ambiguous** — "Should this also cover X, or keep it narrow?"
- **Multiple possible causes** — "I found two potential root causes, which seems right?"
- **Overlapping issues exist** — "Issue #N covers something similar — merge, reference, or separate?"

### Ask before creating

Present the draft and ask:

1. **Assignee** — "Who should own this?" (default: current user if they want)
2. **Priority** — "What priority? Critical / High / Medium / Low?" (if repo uses priority labels)
3. **Adjustments** — "Anything to change before I file it?"

**Do NOT create the issue until the user confirms.**

---

## Step 4: Create the issue

```bash
gh issue create --repo $REPO \
  --title "<type>: short description" \
  --body "<filled-in template>" \
  --assignee <confirmed-assignee> \
  --label <bug|enhancement>
```

### Checklist before creating

- [ ] Correct template format used (bug vs feature)
- [ ] All sections filled in from research
- [ ] Acceptance criteria are specific and testable
- [ ] Assignee confirmed by user
- [ ] No duplicate of an existing open issue
- [ ] Related issues linked in the body

After creating:
- Share the issue URL with the user
- If priority labels exist on the repo, apply them
- If the issue references other issues, add cross-links in those issues

---

## Step 5: Split if needed

If the issue covers **multiple distinct areas** that could be worked on independently, propose splitting.

Signs to split:
- Multiple unrelated acceptance criteria
- Different domains/modules involved
- Different people could work on different parts
- "Fix X **and** improve Y"

### Splitting flow

1. Propose the split — list sub-issues with titles and one-line scopes
2. User confirms or adjusts
3. Create sub-issues as standalone issues (inherit assignee from parent unless user says otherwise)
4. Close the parent with a comment linking to the new issues

### Before creating sub-issues

Check for duplicates:
```bash
gh issue list --repo $REPO --state open --limit 100 --json number,title
```

If a sub-issue duplicates an existing issue, update the existing one instead and close the duplicate with a reference link. Do not create redundant issues.

### When NOT to split

- Parts are tightly coupled
- Issue is already small and focused
- Splitting would create issues too small to be useful

---

## Rules

- **Research before drafting.** Never create an issue from just the user's description without investigation.
- **Ask before creating.** Always get user confirmation on assignee, priority, and content.
- **Use repo templates.** Match the project's existing issue format.
- **Check for duplicates.** Don't create redundant issues.
- **Be specific.** Acceptance criteria should be testable, not vague.
