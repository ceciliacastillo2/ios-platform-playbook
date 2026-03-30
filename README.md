# iOS Platform Playbook

A living reference for the iOS team covering architecture, quality, observability, delivery, and AI integration.

## Claude Commands

AI-assisted commands for navigating this playbook inside Claude Code.

| Command | Description |
|---|---|
| `/ios_playbook_guide [topic]` | Explains architecture decisions and team standards for a given topic |
| `/ios_playbook_update` | Syncs the latest playbook content and commands from the source repo |

**Available deep-dives** — `/ios_playbook_guide <topic>` e.g.:
- `architecture` — folder structure, package by feature, layer responsibilities
- `DI` — dependency injection setup
- `networking` — API client, endpoints
- `feature flags` — LaunchDarkly integration
- `logging` — Luciq logger
- `delivery ci` — CI roadmap and phases
- `navigation` — coordinator pattern

**Install globally** (works in every repo on your machine):
```bash
./install-commands.sh
```

**Install into a specific repo:**
```bash
./install-commands.sh /path/to/your/repo
```

---

## Structure

| Folder | Purpose |
|---|---|
| `architecture/` | System design, diagrams, ADRs, and guiding principles |
| `operating-model/` | How the team works rituals, playbooks, and release process |
| `focus-areas/` | Deep dives by discipline |
| `templates/` | Reusable templates for ADRs, runbooks, and more |

### Focus Areas

| Area | Covers |
|---|---|
| `architecture/` | System design decisions and patterns |
| `quality/` | Testing strategy, static analysis, code health |
| `observability/` | Logs, metrics, traces, crash monitoring, dashboards |
| `delivery/` | CI/CD pipelines and release trains |
| `ai-integration/` | AI experimentation and integration ideas |

---

## Why These Initiatives Matter

| Project | Business Value | What It Unlocks |
|---|---|---|
| Release Automation | Ship faster with no manual steps. Any team member can release, not just one person. Releases stop being events that require courage. | Unit tests actually protect you — they only matter if they run automatically. Snapshot tests catch visual regressions before users do. Growth is safe — doubling the team doesn't double the release complexity. |
| Protocol Adoption | Every future feature costs less to build and is safer to change. Engineers stop stepping on each other. | Unit testing becomes possible. Domain ownership becomes enforceable. Safe refactoring becomes achievable. |
| Design System (tokens + colors) | The app looks like one product. A brand change is a config change, not a sprint. Design and engineering speak the same language. | Snapshot testing becomes meaningful. New screens are built faster from existing primitives. Design handoff stops being approximate. |
| Unit Tests | Catch bugs before users do. Refactor without fear. | Engineering confidence compounds — the team moves faster because the build tells you when something breaks. |
| Snapshot Tests | The UI looks right on every release, automatically. No visual regression reaches production silently. | Design system adoption is enforced. Visual drift is a CI failure, not a user complaint. |
| Domain Ownership | One team owns one domain end to end. A bug in Cards doesn't require an all-hands. QA knows who to call. | Parallel development without coordination overhead. Hiring becomes easier — new engineers own something real from day one. |
| Error Standardization | Users see clear, consistent error messages across every screen. Every domain handles failures the same way — no more guessing what an error means or where it came from. | Debugging becomes faster — errors carry enough context to trace the source without guesswork. Logging and observability improve automatically. New features get correct error handling from day one, not as an afterthought. |
| Performance | App feels faster. Direct impact on activation and retention. | Only meaningful once you have boundaries to isolate the problem and tests to verify the fix. |

---

## Current Focus

> These topics are actively being worked on or defined as of Q2 2026.

| Priority | Topic | Sub-topics | Notes |
|:---:|---|---|---|
| 1 | **System Design** | Color tokens & typography · Dark mode support · Component library | |
| 2 | **Testing** | Unit testing strategy · UI / integration testing · Snapshot testing · Mock / stub infrastructure | Unlocks Navigation work |
| 3 | **CI/CD & Release Management** | Build pipelines · Code signing & provisioning · Phased rollout strategy | See `delivery/ci.md` for roadmap |
| 4 | **DI** | DI framework setup · Module organization · Scoped dependencies | |
| 5 | **Navigation** | Deep linking · Back stack · URL schemes · Universal links | Depends on Testing infrastructure |

---

## Topics Reference

| Topic | Focus | Sub-topics |
|---|:---:|---|
| **UI** | | Dark Theme · Accessibility · Performance · Analytics |
| **Navigation** | `active` | Deep Linking · Back Stack Management · Navigation Architecture · URL scheme handling · Universal / App Links · Navigation routing from links |
| **DI** | `active` | DI framework setup · Module organization · Scoped dependencies |
| **Third Party Dependencies** | `active` | SDK management · License compliance · Version pinning |
| **Session** | | Session lifecycle · Token storage · Session expiration & refresh |
| **Feature Flags** | | Flag evaluation logic · Remote config integration · Deprecated Flags |
| **Logging** | | Log levels · Remote log shipping · PII scrubbing |
| **Performance** | | App startup time · Frame rate / jank monitoring · Memory profiling · Network latency tracking · LuicQ · Apple statistics |
| **Architecture** | | Pattern (MVVM/MVI/Clean) · Layer separation · Module boundaries |
| **Security** | | Certificate pinning · Keychain / Secure storage · Obfuscation & tamper detection · Biometric auth |
| **Networking** | | API client abstraction · Retry / backoff strategies · Offline mode · Response caching · Observability |
| **Error Handling & Crash Reporting** | | Global error boundaries · Crash reporting · User-facing error UX · Non-fatal error tracking |
| **Push Notifications** | | Permission handling · Notification routing · Background processing |
| **System Design** | `active` | Color tokens & typography · Dark mode support · Component library |
| **Accessibility** | | Screen reader support · Dynamic text sizing · Touch target sizes · Color contrast |
| **Localization** | | String management · Date / number / currency formatting |
| **Testing** | `active` | Unit testing strategy · UI / integration testing · Snapshot testing · Mock / stub infrastructure |
| **CI/CD & Release Management** | `active` | Build pipelines · Environment configs · Code signing & provisioning · Phased rollout strategy |
| **App Update & Versioning** | | Forced update flows · In-app update prompts · API versioning compatibility |
| **Onboarding & Auth Flows** | | |
| **Background Processing** | | Background fetch / sync · Long-running tasks · Work scheduling |
| **Permissions** | | |
| **Experimentation** | | |
| **Observability** | | |
