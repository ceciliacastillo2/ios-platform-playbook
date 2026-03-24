# Core/FeatureFlags

## Current State

Feature flags are managed via LaunchDarkly and centralised in `RemoteConfigurationManager`. All flags are defined in one place, which is good for discoverability.

However, the current implementation has two structural problems:

1. **Singleton access**  feature code calls `RemoteConfigurationManager.shared` directly across all layers (views, models, coordinators, view models, use cases)
2. **No protocol abstraction**  LaunchDarkly is a concrete dependency with no interface, making it impossible to mock in tests or swap providers

---

## Current Flags

| Flag Key | Controls | Scope |
|---|---|---|
| `last-supported-ios-app-version` | Minimum supported app version / force update | Global |
| `ios-add-to-wallet` | Add to Wallet feature availability | Global |
| `show-rejected-transactions` | Rejected transactions visibility | Global |
| `global-allow-pin-change-virtual-cards` | PIN change for virtual cards | Global |
| `cards-pin-display-time-in-seconds` | PIN on-screen display duration | Global |
| `invoice-validation-for-claridians` | Invoice validation (internal users only) | Mexico only |
| `{br/co/mx}-show-dynamic-cvv-content` | Dynamic CVV content | Per country |
| `{br/co}-allow-online-pin-change-physical-cards` | Online PIN change for physical cards | BR / CO (MX hardcoded off) |
| `{br/co/mx}-allow-offline-pin-change-physical-cards` | Offline PIN change for physical cards | Per country |
| `{country}-use-legacy-otp` | Legacy OTP validation flow | Per country |

---

## Goal

Introduce a `FeatureFlagProviding` protocol in the Core module. The concrete LaunchDarkly implementation lives behind that protocol. Feature code receives the protocol via dependency injection no direct SDK imports or singleton access in feature modules.

Flag reads should only happen at the ViewModel or UseCase layer, never in Views or domain Models.

---

## Target Structure

```
Core/FeatureFlags/
├── FeatureFlagProviding.swift       ← protocol
└── LaunchDarklyFlagManager.swift    ← LaunchDarkly impl
```
