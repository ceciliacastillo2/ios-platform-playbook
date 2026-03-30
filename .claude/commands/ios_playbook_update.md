---
description: Updates the playbook and Claude commands from the ios-play-book source repo. Usage: /ios_playbook_update
allowed-tools: Read, Bash
---

Update the local playbook copy and Claude commands from the ios-play-book source.

## Steps

1. Read `.claude/playbook-source` to get the path to the ios-play-book repo.
   - If the file does not exist, tell the engineer: "Playbook source not configured. Re-run install-commands.sh from the ios-play-book repo." and stop.

2. Verify the source path exists on disk. If not, tell the engineer the path is stale and they need to re-run install-commands.sh, then stop.

3. Run the following to sync the playbook content:
   ```bash
   rsync -a --delete \
     --include='architecture/***' \
     --include='delivery/***' \
     --include='quality/***' \
     --include='observability/***' \
     --exclude='*' \
     "$(cat .claude/playbook-source)/" "./playbook/"
   cp "$(cat .claude/playbook-source)/README.install.md" "./playbook/README.md"
   ```

4. Run the following to sync the Claude commands:
   ```bash
   cp "$(cat .claude/playbook-source)/.claude/commands/"*.md ".claude/commands/"
   ```

5. Tell the engineer what was updated and that the playbook is now current.
