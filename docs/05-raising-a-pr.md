# Raising a Pull Request

## 1. Create a feature branch

If not already on a feature branch (e.g. from a worktree):

```bash
git checkout -b fix/short-description
# or
git checkout -b feat/short-description
```

Branch naming: `fix/`, `feat/`, `refactor/`, `chore/` prefix + kebab-case description.

## 2. Commit your changes

See [04-pre-commit-checks.md](04-pre-commit-checks.md) for the full checklist.

```bash
git add <specific-files>
git commit -m "refactor: short description

Closes #102"
```

## 3. Push the branch

```bash
git push -u origin <branch-name>
```

## 4. Create the PR (always as draft)

**Always create as a draft PR** — never open a non-draft PR.

```bash
gh pr create --repo <owner/repo> --base <default-branch> --draft \
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

## PR body structure

### Summary
- 1-3 bullet points describing what changed and why

### Test plan
- Checklist of verification steps performed
- Include both automated checks and manual testing
- Mark completed items with `[x]`

### Closes
- Reference the issue: `Closes #102`
- This auto-closes the issue when the PR is merged

## PR title guidelines

- Keep under 70 characters
- Use conventional commit prefix: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`
- Describe the "what", not the "how"
- Use imperative mood: "add feature" not "added feature"

## After creating the PR

- Share the PR URL
- Monitor CI checks
- Address review comments promptly (use `/review-cycle`)
- Keep the PR focused — one issue per PR

## Marking ready for review

After all checks pass and review comments are addressed, **ask the user** before marking ready:

```bash
# Only after explicit user approval:
gh pr ready <N> --repo <owner/repo>
```
