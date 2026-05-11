---
name: cross-check
description: Run all quality checks for the current project — typecheck, lint, format, build, and Rust checks. Auto-detects available commands.
allowed-tools: Bash(pnpm *) Bash(npm *) Bash(yarn *) Bash(bun *) Bash(cargo *) Bash(node *) Bash(cat *) Bash(go *) Bash(python *) Bash(pytest *) Bash(ruff *) Bash(mypy *)
---

# Cross-Check

Run all available quality checks for the current project. Auto-detects what's available.

## Detect package manager

```bash
if [ -f bun.lockb ]; then PKG=bun; elif [ -f pnpm-lock.yaml ]; then PKG=pnpm; elif [ -f yarn.lock ]; then PKG=yarn; else PKG=npm; fi
```

## Run checks in order

### 1. TypeScript / JavaScript checks

Detect and run available scripts from `package.json`:

```bash
# Check which scripts exist
node -e "
const p = require('./package.json');
const s = p.scripts || {};
const checks = ['typecheck', 'lint', 'format:check', 'build'];
checks.forEach(c => { if (s[c]) console.log(c); });
" 2>/dev/null
```

Run each detected check:

- **Typecheck**: `$PKG run typecheck` — must pass with zero errors
- **Lint**: `$PKG run lint` — fix all errors. If auto-fixable: `$PKG run lint -- --fix`
- **Format check**: `$PKG run format:check` — if it fails, run `$PKG run format` then re-check
- **Build**: `$PKG run build` — must complete without errors

### 2. Rust checks (if Cargo.toml exists)

```bash
if [ -f Cargo.toml ]; then
  cargo fmt --all --check
  cargo check
fi
```

If there's a secondary Cargo.toml (e.g. in a Tauri app):
```bash
# Check for nested Rust projects
find . -name Cargo.toml -not -path ./Cargo.toml -not -path '*/vendor/*' -not -path '*/target/*' 2>/dev/null
```

Run `cargo fmt --check` and `cargo check` for each.

### 3. Completeness grep

If the task involved removing or replacing something, verify none remain:

```bash
# Example: verify a removed pattern is fully gone
# grep -rn 'pattern' src/ --include='*.ts' --include='*.tsx' | grep -v node_modules | grep -v .test.
```

### 3. Python checks (if pyproject.toml or setup.py exists)

```bash
if [ -f pyproject.toml ] || [ -f setup.py ]; then
  # Linting
  command -v ruff &>/dev/null && ruff check .
  # Type checking
  command -v mypy &>/dev/null && mypy .
  # Tests
  command -v pytest &>/dev/null && pytest
fi
```

### 4. Go checks (if go.mod exists)

```bash
if [ -f go.mod ]; then
  go vet ./...
  go test ./...
  command -v golangci-lint &>/dev/null && golangci-lint run
fi
```

## When to run what

| Scenario | Minimum checks |
|----------|---------------|
| TypeScript-only change | typecheck, lint, format |
| Component/UI change | typecheck, lint, format, build |
| Rust change | cargo check, cargo fmt |
| Python change | ruff, mypy, pytest |
| Go change | go vet, go test |
| Cross-stack change | All applicable checks above |

## If checks fail

Fix the issues, don't just report them. After fixing, re-run the failing check to confirm it passes.
