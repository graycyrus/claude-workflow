# Working on an Issue

## Phase 0: Context first

Before anything else:
1. **Read project instructions** (CLAUDE.md, memory files) for rules, patterns, conventions
2. **Check recent commits** (`git log --oneline -20`) to understand current momentum
3. **Read the full issue** via `gh issue view <number>`

## Phase 1: Understand (/brb-architectobot) — use Sonnet

Run `/brb-architectobot` to deeply understand the issue before writing any code. **Use Sonnet (not Opus) for this phase** — exploration is mostly grep/read which doesn't need the expensive model.

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

## Phase 1.5: Deep audit (SKIP for obvious bugs)

**Skip this phase entirely for:**
- Missing field / wrong field bugs (e.g. model field not sent)
- Sentry noise suppression (adding phrases to classifiers)
- Config/validation fixes
- Typos, wrong error messages
- Any bug where the fix is clearly scoped to 1-3 files

**Only run deep audit for:**
- New features or large refactors
- Changes touching shared state, Redux, or persisted data
- UI component changes that many screens consume
- Anything that could break other callers

When running the audit (use **Sonnet**, not Opus):

1. **Does any proposed code already exist?** — Search for existing helpers, patterns
2. **Who consumes the state/components being changed?** — Find callers
3. **State persistence / migration concerns?** — New persisted fields?
4. **Test references?** — Do tests assert on behavior being changed?

Revise the plan based on findings.

## Phase 2: Clarify and get approval (10-min timeout)

After the analysis:
- Review the plan — does it match your understanding?
- **Ask the user clarifying questions if there are ANY doubts** — never assume
- Present the plan and **wait up to 10 minutes** for user approval
- If the user responds within 10 minutes — follow their feedback
- **If no response after 10 minutes — auto-approve the plan and proceed to Phase 3**
- If wrong or incomplete, re-examine specific areas

> **Autonomous mode:** When running autonomously (e.g. via sentry-patrol, cron, or background agents), skip the approval wait entirely — treat the plan as auto-approved and proceed immediately.

## Phase 3: Implement (/brb-codecrusher) — use Opus

Run `/brb-codecrusher` to write the actual code changes. **Use Opus for this phase** — implementation needs the best reasoning for correct code.

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

## Phase 4: Verify (cross-checks only, unless 4+ acceptance criteria)

**For issues with fewer than 4 acceptance criteria:** skip architectobot verification. Cross-checks in Step 5 (typecheck, lint, format, cargo check) catch real breakage. Trust them.

**For issues with 4+ acceptance criteria:** re-run architectobot (**Sonnet**) to verify each criterion is met. Complex features have non-code requirements (docs, config, UI behavior) that automated checks miss.

If skipping verification, note any manual checks needed in the PR description.

## Agent summary

| Phase | Agent | Purpose |
|-------|-------|---------|
| Context | (none) | Read project docs, check git log, read issue |
| Understand | /brb-architectobot (**Sonnet**) | Explore code, create plan |
| Audit | Skip for obvious bugs, Sonnet for complex ones | Deep check only when needed |
| Clarify | (you + user, 10-min timeout) | Review plan, auto-approve if no response |
| Implement | /brb-codecrusher (**Opus**) | Write code changes |
| Verify | cross-checks (+ Sonnet if 4+ acceptance criteria) | skip agent pass for simple bugs |

## Key rules

- **Ask before assuming.** If anything is unclear — ask the user. But don't block forever.
- **10-min approval timeout.** Present the plan, wait 10 minutes. No response = auto-approved.
- **Be autonomous.** Use your judgment on trade-offs — pick the simpler approach, avoid over-engineering, and keep moving. Only block on genuinely ambiguous requirements.
- **Read project instructions first.** They contain rules that override defaults.
- **Check recent commits.** Understand what's been happening.
