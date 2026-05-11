---
name: brb-implement
description: Plan, implement, and verify a GitHub issue using architectobot and codecrusher agents. Covers understanding, deep audit, implementation, and acceptance verification.
allowed-tools: Bash(git *) Bash(gh *) Bash(pnpm *) Bash(npm *) Bash(yarn *) Bash(bun *) Bash(cargo *) Bash(node *) Agent(*)
argument-hint: "[issue-number]"
---

# Implement an Issue

You are implementing a GitHub issue through a structured agent workflow. Follow every phase in order.

## Environment detection

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
```

If `REPO` is empty, **STOP and ask the user** to check `gh auth login` and remotes.

If `$ARGUMENTS` contains an issue number, read it:
```bash
gh issue view $ARGUMENTS --repo $REPO
```

---

## Phase 1: Understand (/brb-architectobot)

Run `/brb-architectobot <issue-number>` to deeply understand the issue before writing any code.

What to expect back:
- List of files to modify
- Exact changes needed per file
- Potential risks or edge cases
- Verification steps

---

## Phase 2: Deep audit

Before presenting the plan to the user, run a deep audit (using architectobot or an explore agent):

1. **Does any proposed code already exist?** — Search for existing helpers, components, patterns that do the same thing.
2. **Who consumes the state/components being changed?** — Find every importer and caller. What breaks if behavior changes?
3. **Are there existing UI patterns to reuse?** — Don't reinvent existing components.
4. **State persistence / migration concerns?** — Adding new persisted fields? Check config, versioning, defaults.
5. **Test references?** — Do any tests assert on the behavior being changed?
6. **Side effects?** — Does the code dispatch actions, register listeners, or call APIs as a side effect?

Revise the plan based on findings. Call out what changed and why.

---

## Phase 3: Get approval

Present the revised plan to the user. Call out:
- What changed from the original plan and why
- Files confirmed safe to NOT touch
- Potential conflicts or risks

**The plan must be explicitly approved by the user before proceeding.** If anything is unclear, ask. Never assume.

---

## Phase 4: Implement (/brb-codecrusher)

Run `/brb-codecrusher` to write the actual code changes.

Provide it with:
- The exact files and changes from the approved plan
- Any constraints (don't touch other code, keep existing patterns, etc.)
- Verification command to run after edits

---

## Phase 5: Verify (/brb-architectobot)

Run `/brb-architectobot <issue-number>` again, asking it to verify every acceptance criterion from the issue is met end-to-end.

What it checks:
- Every acceptance criterion from the issue
- No regressions introduced
- Docs updated if needed
- Stale references cleaned up

Fix anything flagged before considering implementation complete.

---

## Key rules

- **Ask before assuming.** If anything about the issue, scope, or approach is unclear — ask the user.
- **Every plan needs approval.** Never start implementation without the user saying "go ahead".
- **Read project instructions first.** CLAUDE.md, memory files, recent commits.
