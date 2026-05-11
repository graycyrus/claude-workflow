# Pre-Commit Checks

## Git hooks

Many projects use Husky or similar git hooks that run automatically on `git commit` and `git push`:

- **Pre-commit**: Runs lint-staged (ESLint + Prettier on staged files)
- **Pre-push**: Runs TypeScript compilation check

If a hook fails, the commit/push is blocked. Fix the issue and retry.

## Manual checks before committing

Always run these before staging and committing:

### 1. TypeScript
```bash
<pkg> run typecheck
```

### 2. Lint
```bash
<pkg> run lint
```

If auto-fixable: `<pkg> run lint -- --fix`

### 3. Format
```bash
<pkg> run format:check
```

If failures: `<pkg> run format`

### 4. Rust (if Rust files changed)
```bash
cargo fmt --all --check
cargo check
```

## Build verification

```bash
<pkg> run build
```

## Staging files

Be specific about what you stage. **Never** use `git add -A` or `git add .` which can accidentally include:
- `.env` files with secrets
- Unrelated lock file changes
- Debug artifacts

Instead:
```bash
git add file1.ts file2.tsx file3.md
```

## Commit message style

Follow conventional commit style:

```
type(scope): short description

# Examples:
refactor: replace dynamic imports with static imports
fix: resolve CORS error in RPC calls
feat: add team management panel to settings
```

Common types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`

## Checklist

Before every commit:
- [ ] Typecheck passes
- [ ] Lint passes (0 errors)
- [ ] Format check passes
- [ ] Build passes
- [ ] Only relevant files staged
- [ ] Commit message follows convention
- [ ] If closing an issue, include `Closes #<number>` in commit body
