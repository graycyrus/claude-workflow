# Picking Up an Issue

## Finding assigned issues

```bash
gh issue list --repo <owner/repo> --assignee <your-github-username> --state open
```

Lists all open issues assigned to you with issue number, title, labels, and date.

## Discovering unassigned issues

If you don't have an assigned issue and want to pick one up, run this selection funnel:

### 1. Fetch all unassigned open issues

```bash
gh issue list --repo <owner/repo> --state open --assignee "" --limit 50 --json number,title,labels,assignees
```

### 2. Filter by complexity

Drop anything clearly hard or large-scope (multi-system rewrites, new infra from scratch, deep platform work). Keep **easy to medium** complexity.

### 3. Filter by description quality

Fetch the body of each candidate. Drop issues with **< ~2k chars** — they're too thin to act on without guessing.

```bash
gh issue view <N> --repo <owner/repo> --json body --jq '.body' | wc -c
```

### 4. Filter by priority

Among remaining candidates, prefer:
1. `priority: high`
2. `priority: medium`
3. `priority: low`
4. Unlabeled

### 5. Select and confirm

Show the top candidate to the user with: issue number, title, priority, labels, and the first ~5 lines of the description.

- **User says go ahead** -> assign the issue:
  ```bash
  gh issue edit <N> --repo <owner/repo> --add-assignee <username>
  ```
- **User says no** -> show the next candidate

---

## Reading issue details

```bash
gh issue view <issue-number> --repo <owner/repo>
```

Read the full issue including:
- **Summary** — what needs to be done
- **Problem** — why it matters
- **Solution** — proposed approach
- **Acceptance criteria** — what "done" looks like
- **Related links** — connected issues, docs, or code references

## Choosing what to work on

Pick based on:
1. **Priority** — bugs before features, blockers before nice-to-haves
2. **Scope** — start with smaller, well-defined issues
3. **Dependencies** — avoid issues blocked by other unfinished work
4. **Labels** — `bug` for fixes, `enhancement` for features, `tech-debt` for cleanup

## Before starting

1. **Read project instructions** (CLAUDE.md, memory files) — understand rules and conventions
2. **Check recent commits** — get context on what's been changing
3. **Confirm you understand the acceptance criteria** — ask if anything is unclear
4. **Check if anyone else is actively working on it** — look at comments, linked PRs
5. **Make sure your default branch is up to date**

## Golden rule

**When in doubt, ask.** Never assume intent, scope, or approach. Every plan must be explicitly approved by the user before implementation begins.
