#!/bin/bash
# Installs iOS Playbook into the Clara iOS repo:
#   - Copies playbook content into playbook/
#   - Copies Claude commands into .claude/commands/

set -e

PLAYBOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
COMMANDS_DIR="$PLAYBOOK_DIR/.claude/commands"

if [ ! -d "$COMMANDS_DIR" ]; then
  echo "Error: .claude/commands not found. Run this script from the ios-play-book root."
  exit 1
fi

echo "iOS Playbook — Installer"
echo "------------------------"
read -rp "Enter the path to the Clara iOS repo: " REPO_PATH

# Expand ~ if used
REPO_PATH="${REPO_PATH/#\~/$HOME}"

if [ ! -d "$REPO_PATH" ]; then
  echo "Error: Directory not found: $REPO_PATH"
  exit 1
fi

if [ ! -d "$REPO_PATH/.git" ]; then
  echo "Warning: $REPO_PATH does not look like a git repo. Continue anyway? (y/n)"
  read -rp "" CONFIRM
  if [ "$CONFIRM" != "y" ]; then
    exit 1
  fi
fi

# 1. Copy playbook content into playbook/
PLAYBOOK_TARGET="$REPO_PATH/playbook"
echo ""
echo "Copying playbook into $PLAYBOOK_TARGET ..."
mkdir -p "$PLAYBOOK_TARGET"
rsync -a --delete \
  --include='architecture/***' \
  --include='delivery/***' \
  --include='quality/***' \
  --include='observability/***' \
  --exclude='*' \
  "$PLAYBOOK_DIR/" "$PLAYBOOK_TARGET/"
cp "$PLAYBOOK_DIR/README.install.md" "$PLAYBOOK_TARGET/README.md"

# 2. Save playbook source path so /ios_playbook_update can find it
echo "Saving playbook source path ..."
echo "$PLAYBOOK_DIR" > "$REPO_PATH/.claude/playbook-source"

# 3. Copy Claude commands
COMMANDS_TARGET="$REPO_PATH/.claude/commands"
echo "Installing Claude commands into $COMMANDS_TARGET ..."
mkdir -p "$COMMANDS_TARGET"
cp "$COMMANDS_DIR"/*.md "$COMMANDS_TARGET"/

echo ""
echo "Done."
echo "  playbook/          ← team standards and architecture docs"
echo "  .claude/commands   ← available commands:"
for f in "$COMMANDS_DIR"/*.md; do
  echo "    /$(basename "$f" .md)"
done
echo ""
echo "Open Claude Code in the Clara iOS repo — the playbook is active."
echo "Run /ios-update any time to pull the latest changes."
