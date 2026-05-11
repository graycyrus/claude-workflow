# Working on an Issue

## Phase 0: Context first

Before anything else:
1. **Read project instructions** (CLAUDE.md, memory files) for rules, patterns, conventions
2. **Check recent commits** (`git log --oneline -20`) to understand current momentum
3. **Read the full issue** via `gh issue view <number>`

## Phase 1: Understand (architectobot)

Run `/brb-architectobot` to deeply understand the issue before writing any code.

**What it does:**
- Reads the GitHub issue
- Explores the codebase to find all relevant files
- Identifies existing patterns, utilities, and functions to reuse
- Maps dependencies and impact areas
- Produces a detailed implementation plan

**How to invoke:**
> `/brb-architectobot <issue-number>`

**What to expect back:**
- List of files to modify
- Exact changes needed per file
- Potential risks or edge cases
- Verification steps

## Phase 1.5: Deep audit

Before presenting the plan to the user, run a deep audit:

1. **Does any proposed code already exist?** — Search for existing helpers, components, patterns
2. **Who consumes the state/components being changed?** — Find every importer and caller
3. **Are there existing UI patterns to reuse?** — Don't reinvent existing components
4. **State persistence / migration concerns?** — New persisted fields? Check config, versioning, defaults
5. **Test references?** — Do tests assert on behavior being changed?
6. **Side effects?** — Dispatched actions, listeners, API calls as side effects?

Revise the plan based on findings.

## Phase 2: Clarify and get approval

After the analysis:
- Review the plan — does it match your understanding?
- **Ask the user clarifying questions if there are ANY doubts** — never assume
- **The plan must be explicitly approved by the user** before moving to Phase 3
- If wrong or incomplete, re-examine specific areas

## Phase 3: Implement (codecrusher)

Run `/brb-codecrusher` to write the actual code changes.

**What it does:**
- Reads each file before editing (never edits blind)
- Makes precise, minimal changes per the plan
- Follows existing code patterns and conventions
- Runs typecheck after all edits

**How to invoke:**
> `/brb-codecrusher`

Provide:
- The exact files and changes from the plan
- Any constraints
- Verification command to run after edits

## Phase 4: Verify (architectobot again)

Run `/brb-architectobot` again to verify every acceptance criterion end-to-end.

**How to invoke:**
> `/brb-architectobot <issue-number>` (ask it to verify, not plan)

**What it checks:**
- Every acceptance criterion from the issue
- No regressions introduced
- Docs updated if needed
- Stale references cleaned up

## Agent summary

| Phase | Agent | Purpose |
|-------|-------|---------|
| Context | (none) | Read project docs, check git log, read issue |
| Understand | architectobot | Explore code, create plan |
| Audit | architectobot/explore | Deep check for duplicates, consumers, breakage |
| Clarify | (you + user) | Review plan, ask questions, **get approval** |
| Implement | codecrusher | Write code changes |
| Verify | architectobot | Confirm all acceptance criteria met |

## Key rules

- **Ask before assuming.** If anything is unclear — ask the user.
- **Every plan needs approval.** Never start implementation without "go ahead".
- **Read project instructions first.** They contain rules that override defaults.
- **Check recent commits.** Understand what's been happening.
