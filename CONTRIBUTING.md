# Contributing to claude-workflow

Thanks for your interest in contributing! This project aims to make AI-assisted development workflows accessible to everyone using Claude Code.

## How to contribute

### Improving existing skills

The skills live in `skills/<name>/SKILL.md`. Each is a self-contained Claude Code skill file with YAML frontmatter and markdown instructions.

When improving a skill:
- Keep the auto-detection approach — no hardcoded repo names, usernames, or tool-specific commands
- Test with at least two different project types (e.g. a TypeScript project and a Rust project)
- Maintain the "ask before assuming" philosophy

### Adding a new skill

1. Create `skills/<skill-name>/SKILL.md`
2. Add YAML frontmatter with `description`, `allowed-tools`, and optionally `argument-hint`
3. Include environment detection at the top
4. Add corresponding documentation in `docs/`
5. Update the skill table in `README.md`

### Updating docs

The `docs/` folder contains detailed reference documentation. Keep these in sync with the skills — if a skill changes behavior, update the corresponding doc.

## Guidelines

- **Keep it generic.** Skills should work with any project, not just specific tech stacks.
- **Auto-detect, don't configure.** Prefer runtime detection over config files.
- **Ask, don't assume.** The workflow should always get user confirmation before destructive or irreversible actions.
- **Test across projects.** A good skill works with TypeScript, Rust, Python, Go — not just one.

## Reporting issues

If a skill doesn't work as expected in your project, open an issue with:
- What project type you're using (language, build tool, etc.)
- What happened vs. what you expected
- The skill command you ran

## Code of conduct

Be kind, be helpful, be constructive.
