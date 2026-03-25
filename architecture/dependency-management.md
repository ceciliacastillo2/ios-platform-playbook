# Dependency Management

## Current State

The app relies heavily on singletons for shared state. Session, feature flags, UI managers, and third-party SDKs are all accessed via `.shared` across all layers.

This makes unit testing nearly impossible and creates hidden dependencies between components.

There are 9 singletons in the codebase:

| Singleton | Type | Used in |
|---|---|---|
| `Session.shared` | User session / auth state | Coordinators, ViewModels, Models everywhere |
| `RemoteConfigurationManager.shared` | Feature flags | Coordinators, ViewModels, Views, Models |
| `SnackbarManager.shared` | UI toasts | 5+ coordinators |
| `ZendeskManager.shared` | Support chat | 3 coordinators |
| `RateAppManager.shared` | App rating prompts | 2 coordinators |
| `ImagesRepository.shared` | Image caching | Unknown |
| `LocalNotificationPublisher.shared` | Local notifications | Unknown |
| `BackgroundService.shared` | Background uploads | RequestPerformer |
| `SiftManager.shared` | Fraud detection | Unknown |


## Goal

All shared services injected via `DependencyContainer`. No feature module accesses `.shared` directly. Session state exposed through a `SessionProviding` protocol injected at coordinator and view model construction time.

**What success looks like**

- No `.shared` call exists outside of `Core/DI` — every singleton is registered once and injected everywhere else.
- Every shared service is behind a protocol. Feature code never references a concrete SDK type.
- A ViewModel can be unit tested by passing mock protocols — no real session, network, or SDK needed.
- `Session.shared` is gone from feature modules. ViewModels and Coordinators receive `SessionProviding` at construction time.
- The migration table below is empty — all singletons have been replaced.

---

## Rules

1. **No `.shared` access in feature modules** if a class calls `.shared`, it owns a hidden dependency the compiler cannot see or enforce
2. **Every shared service must have a protocol**  the concrete type is registered in `Core/DI`, feature code only knows the protocol
3. **Session state is injected, not grabbed**  ViewModels and Coordinators receive a `SessionProviding` instance, they never reach for `Session.shared`
4. **Testability is the signal**  if a class cannot be unit tested without a real network or real session, it has a hidden singleton dependency

---

## Migration Priority

| Singleton | Priority | Reason |
|---|---|---|
| `Session.shared` | High | God object, 15+ call sites, blocks all testing |
| `RemoteConfigurationManager.shared` | High | Leaks into Views and Models — wrong layer |
| `SnackbarManager.shared` | Medium | Easy to inject, contained to coordinators |
| `ZendeskManager.shared` | Medium | Already wrapped in Core — just needs injection |
| `SiftManager.shared` | Medium | Already wrapped in Core — just needs injection |
| `RateAppManager.shared` | Low | Limited usage, low risk |
| `ImagesRepository.shared` | Low | Contained, low business risk |
| `LocalNotificationPublisher.shared` | Low | Usage unknown, investigate first |
| `BackgroundService.shared` | Low | Single consumer, easy to refactor |

---

## Target Pattern

```swift
// Before — hidden global dependency
class CardListViewModel {
    func load() {
        let userId = Session.shared.userId
        let flagEnabled = RemoteConfigurationManager.shared.isEnabled(.addToWallet)
    }
}

// After — explicit, injectable, testable
class CardListViewModel {
    private let session: SessionProviding
    private let flags: FeatureFlagProviding

    init(session: SessionProviding, flags: FeatureFlagProviding) {
        self.session = session
        self.flags = flags
    }

    func load() {
        let userId = session.userId
        let flagEnabled = flags.isEnabled(.addToWallet)
    }
}
```
