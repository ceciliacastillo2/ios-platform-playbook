# iOS Platform Playbook

A living reference for the iOS team covering architecture, quality, observability, delivery, and AI integration.

## Claude Commands

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

---

## Structure

| Area | Covers |
|---|---|
| `playbook/architecture/` | System design decisions and patterns |
| `playbook/quality/` | Testing strategy, static analysis, code health |
| `playbook/observability/` | Logs, metrics, traces, crash monitoring, dashboards |
| `playbook/delivery/` | CI/CD pipelines and release trains |

---

## Current Focus

> These topics are actively being worked on or defined as of Q2 2026.

| Priority | Topic | Sub-topics | Notes |
|:---:|---|---|---|
| 1 | **System Design** | Color tokens & typography · Dark mode support · Component library | |
| 2 | **Testing** | Unit testing strategy · UI / integration testing · Snapshot testing · Mock / stub infrastructure | Unlocks Navigation work |
| 3 | **CI/CD & Release Management** | Build pipelines · Code signing & provisioning · Phased rollout strategy | See `playbook/delivery/ci.md` for roadmap |
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
