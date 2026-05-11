# Cross-Checking If Everything Works

## After code changes, verify in this order

### 1. Typecheck

```bash
<pkg> run typecheck
```

Runs TypeScript compilation check — catches type errors without producing output. Must pass with zero errors.

### 2. Lint

```bash
<pkg> run lint
```

Runs ESLint (or your project's linter). Fix all errors. Pre-existing warnings not introduced by your change are acceptable.

### 3. Format check

```bash
<pkg> run format:check
```

Runs Prettier (or your project's formatter) in check mode. If it fails:

```bash
<pkg> run format
```

Then re-run the check to confirm.

### 4. Build

```bash
<pkg> run build
```

Produces the production build. Must complete without errors.

### 5. App launch (if applicable)

If the project has a desktop app or dev server, launch it and verify:
- App/server starts without crash
- No errors in terminal output
- Core functionality works
- No CORS or RPC errors in console

### 6. Grep for completeness

If the task involved removing or replacing something, verify none remain:

```bash
grep -rn 'pattern' src/ --include='*.ts' --include='*.tsx' | grep -v node_modules | grep -v .test.
```

Empty output = all clear.

### 7. Rust checks (if Cargo.toml exists)

```bash
cargo fmt --all --check
cargo check
```

### 8. Python checks (if pyproject.toml or setup.py exists)

```bash
ruff check .          # linting
mypy .                # type checking
pytest                # tests
```

Only run the tools that are installed in the project.

### 9. Go checks (if go.mod exists)

```bash
go vet ./...
go test ./...
golangci-lint run     # if installed
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
