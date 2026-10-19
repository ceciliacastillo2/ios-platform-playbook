# Dependency Management

## Current State (October 2026)

The team has moved off "grab a singleton" toward a single container. `DependencyContainer` is now the app's only singleton and the place shared services are resolved — but the migration is not finished, and a long tail of `.shared` access remains.

**Shared services now reached through the container**

`AppDependencies` exposes the cross-cutting set — `logger`, `analytics`, `pasteboard`, `accessGate` — and each feature's `*Dependencies` bundle carries its own repositories and use cases. Newer features (`Tasks`, `ClaraConta`) consume these; older features still reach for globals.

**The remaining `.shared` surface** (occurrences across the repo)

| Symbol | Occurrences | Where it leaks |
|---|---:|---|
| `Session.shared` | 143 | Coordinators, ViewModels, providers, models — everywhere |
| `DependencyContainer.shared` | 69 | Feature assembly points, not just the composition root |
| `AppRouter.shared` | 57 | Navigation |
| `CLogger.shared` | 52 | Logging |
| `DesignSystemConfig.shared` | 33 | UI |
| `RemoteConfigurationManager.shared` | 31 | Views, Models, Coordinators, ViewModels |
| `SnackbarManager.shared` | 24 | UI toasts |

Inside `Features/` alone: `Session.shared` ×63, `DependencyContainer.shared` ×43, `CLogger.shared` ×35, `SnackbarManager.shared` ×23, `RemoteConfigurationManager.shared` ×15.

Resolved since the original assessment: `ZendeskManager`, `SiftManager`, and `RateAppManager` no longer appear as `.shared` singletons, so they have been dropped from the migration table below.

---

## Goal

All shared services injected via `DependencyContainer`. No feature module accesses `.shared` directly. Session state exposed through a `SessionProviding` protocol injected at coordinator and view model construction time.

**What success looks like**

- No `.shared` call exists outside of `Core/Dependencies` — every singleton is registered once and injected everywhere else.
- Every shared service is behind a protocol. Feature code never references a concrete SDK type.
- A ViewModel can be unit tested by passing mock protocols — no real session, network, or SDK needed.
- `Session.shared` is gone from feature modules. ViewModels and Coordinators receive `SessionProviding` at construction time.
- The migration table below is empty — all singletons have been replaced.

---

## Rules

1. **No `.shared` access in feature modules** — if a class calls `.shared`, it owns a hidden dependency the compiler cannot see or enforce.
2. **Every shared service must have a protocol** — the concrete type is registered in `Core/Dependencies`, feature code only knows the protocol.
3. **Session state is injected, not grabbed** — ViewModels and Coordinators receive a `SessionProviding` instance, they never reach for `Session.shared`.
4. **Testability is the signal** — if a class cannot be unit tested without a real network or real session, it has a hidden singleton dependency.

---

## Migration Priority

| Singleton | Priority | Reason |
|---|---|---|
| `Session.shared` | High | God object, 143 call sites, blocks all testing |
| `RemoteConfigurationManager.shared` | High | Leaks into Views and Models — wrong layer |
| `DependencyContainer.shared` | High | Should be referenced only at the composition root |
| `AppRouter.shared` | Medium | Navigation state reached from outside the coordinator |
| `CLogger.shared` | Medium | Already wrapped in `Core/Logging` — just needs injection |
| `SnackbarManager.shared` | Medium | Easy to inject, contained to coordinators |
| `DesignSystemConfig.shared` | Low | UI-only, low risk |
| `ImagesRepository.shared` | Low | Contained, low business risk |
| `LocalNotificationPublisher.shared` | Low | Usage unknown, investigate first |
| `BackgroundService.shared` | Low | Single consumer, easy to refactor |

---

## Target Pattern

```swift
// Before — hidden global dependency
final class CardListViewModel {
    func load() {
        let companyId = Session.shared.companyId
        let flagEnabled = RemoteConfigurationManager.shared.isAddToWalletFeatureAvailable
    }
}

// After — explicit, injectable, testable
final class CardListViewModel {
    private let session: SessionProviding
    private let flags: FeatureFlagProviding

    init(session: SessionProviding, flags: FeatureFlagProviding) {
        self.session = session
        self.flags = flags
    }

    func load() {
        let companyId = session.companyId
        let flagEnabled = flags.isAddToWalletAvailable
    }
}
```
