---
name: brb-update-workflow
description: Update all claude-workflow skills to the latest version from GitHub.
allowed-tools: Bash(git *) Bash(rm *) Bash(cp *) Bash(mkdir *) Bash(ls *) Bash(cat *) Bash(diff *)
---

# Update Workflow Skills

Check for and install the latest version of claude-workflow skills from GitHub.

## Step 1: Detect current install location

Check where the skills are currently installed:

```bash
# Check global install
if [ -d "$HOME/.claude/skills/brb-workflow" ]; then
  INSTALL_DIR="$HOME/.claude/skills"
  INSTALL_TYPE="global"
  echo "Found global install at $INSTALL_DIR"
fi

# Check project install
if [ -d ".claude/skills/brb-workflow" ]; then
  INSTALL_DIR=".claude/skills"
  INSTALL_TYPE="project"
  echo "Found project install at $INSTALL_DIR"
fi
```

If both exist, tell the user and ask which to update. If neither exists, tell the user the skills don't appear to be installed.

## Step 2: Fetch latest

```bash
TMP_DIR=$(mktemp -d)
git clone --quiet --depth 1 https://github.com/graycyrus/claude-workflow.git "$TMP_DIR"
```

## Step 3: Show what changed

Compare the current install with the latest:

```bash
# List skills that would be updated
for skill in "$TMP_DIR/skills/"*/; do
  name=$(basename "$skill")
  if [ -d "$INSTALL_DIR/$name" ]; then
    if ! diff -q "$skill/SKILL.md" "$INSTALL_DIR/$name/SKILL.md" >/dev/null 2>&1; then
      echo "UPDATED: /$name"
    fi
  else
    echo "NEW: /$name"
  fi
done
```

Show the user which skills have changes and which are new. If nothing changed, say "Already up to date!" and stop.

## Step 4: Apply update

Ask the user: "Apply these updates?"

If yes:

```bash
cp -r "$TMP_DIR/skills/"* "$INSTALL_DIR/"
rm -rf "$TMP_DIR"
echo "Updated! Restart Claude Code to pick up changes."
```

## Step 5: Clean up

```bash
rm -rf "$TMP_DIR"
```

Tell the user what was updated and that they may need to restart Claude Code for changes to take effect.
