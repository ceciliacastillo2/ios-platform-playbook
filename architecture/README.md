# Architecture

System design, guiding principles, and Core module documentation for the ClaraCard iOS app.

## Contents

| File | What it covers |
|---|---|
| [overview.md](overview.md) | App architecture goals, folder structure, and layer responsibilities |
| [dependency-management.md](dependency-management.md) | Singleton audit and the migration plan to full injection |
| [core-di.md](core-di.md) | Dependency injection — the problem, the goal, and the rules |
| [core-feature-flags.md](core-feature-flags.md) | Feature flag protocol, LaunchDarkly isolation, and current flags |
| [core-logging.md](core-logging.md) | Logging protocol, log levels, privacy rules, and migration approach |
| [core-networking.md](core-networking.md) | Networking layer design and endpoint conventions |
| [third-party-integrations.md](third-party-integrations.md) | Every third-party SDK — purpose, wrapper location, and owner |

## Subfolders

| Folder | What it covers |
|---|---|
| [principles/](principles/) | Guiding engineering principles |
| [diagrams/](diagrams/) | Visual architecture diagrams and folder structure reference |
| [decisions/](decisions/) | Architecture Decision Records (ADRs) |
