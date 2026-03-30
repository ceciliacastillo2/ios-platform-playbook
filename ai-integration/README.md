# AI Integration

How the team uses AI tooling in the iOS development workflow — what's active today and where it's headed.

## Active

### Claude Commands

Two Claude Code commands are installed into the iOS repo via the playbook installer:

| Command | What it does |
|---|---|
| `/ios_playbook_guide [topic]` | Explains architecture decisions and team standards for a given topic. Reads directly from the playbook — never invents decisions or examples not defined there. |
| `/ios_playbook_update` | Syncs the latest `architecture/`, `delivery/`, and `quality/` content and commands from the ios-play-book source repo. |

Commands live in `.claude/commands/` and are available in any Claude Code session opened in the iOS repo.

### Playbook as Context

When `CLAUDE.md` exists in the iOS repo and references `./playbook/`, Claude automatically loads the team's architecture standards, decisions, and current focus areas as context on every session without any manual prompting.

## Coming soon

- AI feature experiments and outcomes
- Integration patterns and guidelines
- Tooling and SDK evaluation
