#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/graycyrus/claude-workflow.git"
TMP_DIR=$(mktemp -d)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# Check prerequisites
if ! command -v git &>/dev/null; then
  echo "Error: git is not installed. Install it first."
  exit 1
fi

# Support both interactive and piped (curl | bash) usage
# When piped, default to global install. When interactive, ask.
if [ -t 0 ]; then
  echo "claude-workflow installer"
  echo "========================"
  echo ""
  echo "Where do you want to install the skills?"
  echo ""
  echo "  1) Global   (~/.claude/skills/)    — available in all projects"
  echo "  2) Project  (.claude/skills/)      — available in this project only"
  echo ""
  read -rp "Choose [1/2]: " choice
else
  # Non-interactive (piped) — default to global
  choice="1"
  echo "claude-workflow installer (non-interactive — installing globally)"
fi

case "$choice" in
  1)
    TARGET="$HOME/.claude/skills"
    echo ""
    echo "Installing globally to $TARGET..."
    ;;
  2)
    TARGET=".claude/skills"
    echo ""
    echo "Installing to project at $TARGET..."
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

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
echo "Done! Open Claude Code and try: /workflow"
echo ""
echo "To uninstall: rm -rf $TARGET/{workflow,pick-issue,implement,cross-check,raise-pr,review-cycle,architectobot,codecrusher,memory-keeper}"
