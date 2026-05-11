#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/graycyrus/claude-workflow.git"
SKILLS_LIST="brb-workflow brb-pick-issue brb-implement brb-cross-check brb-raise-pr brb-review-pr brb-review-cycle brb-create-issue brb-architectobot brb-codecrusher brb-memory-keeper brb-update-workflow"

# Check prerequisites
if ! command -v git &>/dev/null; then
  echo "Error: git is not installed. Install it first."
  exit 1
fi

# Support both interactive and piped (curl | bash) usage
if [ -t 0 ]; then
  echo "claude-workflow installer"
  echo "========================"
  echo ""
  echo "Install method:"
  echo ""
  echo "  1) Copy — Global   (~/.claude/skills/)     — simple, update via /brb-update-workflow"
  echo "  2) Copy — Project  (.claude/skills/)        — per-project, update via /brb-update-workflow"
  echo "  3) Symlink — Global (~/.claude/skills/)     — git pull = instant updates"
  echo ""
  read -rp "Choose [1/2/3]: " choice
else
  choice="1"
  echo "claude-workflow installer (non-interactive — installing globally via copy)"
fi

case "$choice" in
  1)
    TARGET="$HOME/.claude/skills"
    METHOD="copy"
    ;;
  2)
    TARGET=".claude/skills"
    METHOD="copy"
    ;;
  3)
    TARGET="$HOME/.claude/skills"
    METHOD="symlink"
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

if [ "$METHOD" = "symlink" ]; then
  # Symlink install — clone to a permanent location, symlink skills
  CLONE_DIR="$HOME/.claude/claude-workflow"

  if [ -d "$CLONE_DIR" ]; then
    echo ""
    echo "Repo already cloned at $CLONE_DIR — pulling latest..."
    git -C "$CLONE_DIR" pull --quiet
  else
    echo ""
    echo "Cloning claude-workflow to $CLONE_DIR..."
    if ! git clone --quiet "$REPO_URL" "$CLONE_DIR"; then
      echo "Error: Failed to clone $REPO_URL."
      exit 1
    fi
  fi

  mkdir -p "$TARGET"

  echo ""
  echo "Creating symlinks..."
  for skill in $SKILLS_LIST; do
    if [ -d "$CLONE_DIR/skills/$skill" ]; then
      # Remove existing (file, dir, or symlink) before linking
      rm -rf "${TARGET:?}/$skill"
      ln -s "$CLONE_DIR/skills/$skill" "$TARGET/$skill"
      echo "  /$skill -> $CLONE_DIR/skills/$skill"
    fi
  done

  echo ""
  echo "Done! Skills are symlinked from $CLONE_DIR."
  echo ""
  echo "To update:  cd $CLONE_DIR && git pull"
  echo "To uninstall:"
  echo "  rm -rf $CLONE_DIR"
  for skill in $SKILLS_LIST; do echo "  rm $TARGET/$skill"; done

else
  # Copy install
  TMP_DIR=$(mktemp -d)
  cleanup() { rm -rf "$TMP_DIR"; }
  trap cleanup EXIT

  echo ""
  echo "Cloning claude-workflow..."
  if ! git clone --quiet --depth 1 "$REPO_URL" "$TMP_DIR" 2>/dev/null; then
    echo "Error: Failed to clone $REPO_URL. Check your network and that the repo exists."
    exit 1
  fi

  if [ ! -d "$TMP_DIR/skills" ]; then
    echo "Error: Cloned repo does not contain a skills/ directory."
    exit 1
  fi

  mkdir -p "$TARGET"
  cp -r "$TMP_DIR/skills/"* "$TARGET/"

  echo ""
  echo "Installed skills:"
  for skill in "$TARGET"/*/; do
    name=$(basename "$skill")
    echo "  /$name"
  done

  echo ""
  echo "Done! Open Claude Code and try: /brb-workflow"
  echo ""
  echo "To update:  run /brb-update-workflow in Claude Code"
  echo "To uninstall: rm -rf $TARGET/{$(echo "$SKILLS_LIST" | tr ' ' ',')}"
fi
