---
name: brb-sentry-patrol
description: Autonomous Sentry bug-fix patrol — picks unresolved issues, creates GitHub issues, delegates fixes to /brb-workflow. Designed for cron/background execution.
allowed-tools: Bash(sentry *) Bash(gh *) Bash(git *) Bash(cat *) Bash(rm *) Agent(*) CronCreate CronList CronDelete
argument-hint: "[--cron 30m] [--once]"
---

# Sentry Patrol — Autonomous Bug-Fix Cycle

You are an autonomous patrol agent. Pick one unresolved Sentry bug, create a GitHub issue, then delegate the fix to `/brb-workflow` in autonomous mode. **No human interaction. No approval gates. Auto-approve everything.**

## NON-NEGOTIABLE: never suppress, always fix the root cause

**ALWAYS find the root cause and fix the actual bug. NEVER suppress, silence, or hide a bug.** This applies to every issue, every fix, every delegated agent — no exceptions.

Forbidden "fixes" — these are suppression, not fixes, and must never be used to close an issue:
- Wrapping the failing code in a bare `try/catch`, `if err != nil { return }`, `.unwrap_or_default()`, `?.`/optional chaining, or any swallow that just makes the error disappear
- Lowering log level, muting alerts, or marking the Sentry issue resolved/ignored without a code fix
- Adding a guard that skips the code path instead of fixing why it failed
- Catching a broad exception to stop the crash without addressing what caused it

Every fix MUST be traced to the underlying defect (the RCA documented in Step 2/3) and correct that defect. Defensive guards are acceptable ONLY when they are part of correcting the real root cause and the RCA is documented — never as a standalone way to make the error stop. If the true root cause cannot be found, log `FAILED` with the reason — do NOT paper over it.

## Setup check

Before first run, verify Sentry CLI is authenticated:

```bash
# Find sentry CLI
SENTRY_CLI=$(which sentry 2>/dev/null || echo "$HOME/.sentry/bin/sentry")

# Verify auth
$SENTRY_CLI auth status 2>&1
```

If not authenticated, tell the user to run:
```bash
$SENTRY_CLI auth login --url <sentry-instance-url> --token <token>
```

Detect project constants:

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "")
GH_USER=$(gh api user -q .login 2>/dev/null || echo "")
SENTRY_ORG=$(grep -r 'org' ~/.sentry/cli.db 2>/dev/null | head -1 || echo "")
```

If `$ARGUMENTS` contains `--cron`, set up recurring patrol:
```
CronCreate(cron: "*/30 * * * *", prompt: "/brb-sentry-patrol --once")
```

If `$ARGUMENTS` contains `--once` or no arguments, run a single patrol cycle below.

## Token optimization rules

- **Sonnet for exploration/planning**, Opus for implementation only
- **Skip deep audit** for obvious bugs (missing fields, classifier updates, 1-3 file fixes)
- **No verification step** unless the issue has 4+ acceptance criteria
- **No `cargo build`** — use `cargo check` only
- **Clean build artifacts** (`target/`, `node_modules/`) after completion to free disk

## Step 1: Pick an issue from Sentry

```bash
$SENTRY_CLI issue list $SENTRY_ORG/ --query "is:unresolved" --sort date --limit 20 --json --fields shortId,title,level,count,userCount,priority,firstSeen,lastSeen,permalink
```

Then read `target/sentry-patrol-log.md` (create it if it doesn't exist). Extract all Sentry short IDs already logged (PICKED, IN_PROGRESS, COMPLETED, FAILED). **Skip those.**

From the remaining issues, pick the **best candidate**:
- Prefer `high` or `medium` priority
- Prefer higher event count (more users affected)
- Prefer `error` level over `warning`
- Skip issues that are clearly external/config (401 auth, 402 billing, localhost refused, user API keys)
- Skip issues from projects not in this repo (check project name vs repo)

If no candidates remain, append to the log:
```
## [TIMESTAMP] NO_ISSUES — patrol found no new actionable issues
```
Then **STOP**.

## Step 2: Get issue details + assign on Sentry

Use `$SENTRY_CLI issue view <shortId>` to get full details including stack trace, breadcrumbs, tags, and spans. Understand the root cause.

Then assign the Sentry issue:
```bash
$SENTRY_CLI api issues/<issue-numeric-id>/ --method PUT --data "{\"assignedTo\":\"$(git config user.email)\"}"
```
(Extract the numeric issue ID from the Sentry permalink URL — it's the number after `/issues/`.)

## Step 3: Log PICKED

Append to `target/sentry-patrol-log.md`:
```
## [TIMESTAMP] PICKED — <shortId>
- **Sentry**: <title summary>
- **Priority**: <priority> | **Events**: <count> | **Project**: <project>
- **Root cause**: <1-2 sentence analysis>
- **Status**: IN_PROGRESS
```

## Step 4: Create GitHub issue

Use `gh issue create` on `$REPO` with:
- Title: `fix: <concise description from Sentry>`  
- Body: Use the bug template from `.github/ISSUE_TEMPLATE/bug.md` if it exists. Include Sentry link, stack trace summary, root cause analysis, and acceptance criteria.
- Labels: `bug`
- Assignee: `$GH_USER`

Update the log entry with the GitHub issue number.

## Step 5: Delegate to /brb-workflow

Launch a **background Agent** with `isolation: "worktree"` and the following prompt:

```
You are running /brb-workflow in AUTONOMOUS MODE for issue #<issue-number>.

NON-NEGOTIABLE — NEVER SUPPRESS THE BUG:
- ALWAYS find the root cause and fix the actual defect. NEVER suppress, silence, or hide it.
- Forbidden: bare try/catch swallows, `.unwrap_or_default()`, optional-chaining the error away, lowering log levels, skipping the code path, or resolving the Sentry issue without a real code fix.
- Defensive guards are allowed ONLY as part of correcting the documented root cause — never as a standalone way to make the error stop.
- If the true root cause cannot be found, log FAILED with the reason. Do NOT paper over it.

AUTONOMOUS MODE RULES (override all interactive gates):
- Skip session resume check — this is a fresh run
- Step 1: Issue already picked — use #<issue-number>
- Step 2: Auto-approve the architectobot plan after creating it. Do NOT wait for user input.
- Step 2.5: Skip deep audit (this is a Sentry bug fix, likely 1-3 files)
- Step 4: Skip verification unless 4+ acceptance criteria
- Step 5: Use `cargo check` NOT `cargo build`. Skip `pnpm build` if Rust-only change.
- Step 6: Skip memory update
- Step 9: Open PR directly (NOT draft)
- Step 10: Run the full PR review cycle autonomously (comments + CI + conflicts loop)
- Step 11: Mark ready immediately — do NOT ask user
- Step 12: Do NOT remove worktree. DO clean build artifacts after 10 mins:
  `rm -rf target/ node_modules/ app/node_modules/`

TOKEN OPTIMIZATION:
- Use Sonnet for exploration/planning agents
- Use Opus only for implementation (codecrusher)
- Skip deep audit for obvious bugs
- No cargo build, cargo check only

CONTEXT:
- Sentry ID: <shortId>
- Sentry link: <permalink>
- Root cause: <root cause analysis>
- GitHub issue: #<issue-number>

Now run the full /brb-workflow with these overrides.
```

Pass the Sentry details, root cause analysis, and GitHub issue number into the prompt.

## Step 6: Update log and return

After spawning the background agent, return immediately with a one-line status:
> Patrol cycle: picked <shortId>, spawned /brb-workflow agent in background. See `target/sentry-patrol-log.md`.

Do NOT wait for the agent to finish.

The background agent is responsible for updating `target/sentry-patrol-log.md` with COMPLETED or FAILED when done:

```
## [TIMESTAMP] COMPLETED — <shortId>
- **PR**: <owner/repo>#<pr-number>
- **GitHub Issue**: #<issue-number>
- **Branch**: <branch-name>
- **Changes**: <1-2 sentence summary>
- **Checks**: typecheck <OK/FAIL>, lint <OK/FAIL>, format <OK/FAIL>, cargo check <OK/FAIL>
```

```
## [TIMESTAMP] FAILED — <shortId>
- **GitHub Issue**: #<issue-number>
- **Step failed**: <which step>
- **Error**: <error summary>
- **Worktree**: <path> (preserved for debugging)
```
