#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/graycyrus/claude-workflow.git"
TMP_DIR=$(mktemp -d)

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

echo "claude-workflow installer"
echo "========================"
echo ""
echo "Where do you want to install the skills?"
echo ""
echo "  1) Global   (~/.claude/skills/)    — available in all projects"
echo "  2) Project  (.claude/skills/)      — available in this project only"
echo ""
read -rp "Choose [1/2]: " choice

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
git clone --quiet --depth 1 "$REPO_URL" "$TMP_DIR"

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
