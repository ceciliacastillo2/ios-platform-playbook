# Third-Party Integrations

## Overview

The app relies on several third-party SDKs for things like authentication, fraud detection, customer support, feature flags, localization, bug reporting, push notifications, and digital card provisioning.

The iOS team owns and maintains all of these integrations. Feature areas consume them through wrappers defined in `Core/` — no feature module should ever import an SDK directly.

The pattern is simple: one file imports the SDK, everything else talks to a protocol.

---

## Rules

1. **Every SDK lives behind a single wrapper in `Core/`.** That wrapper is the only file in the codebase allowed to import the SDK.

2. **Feature modules depend on the wrapper's protocol, not the SDK's types.** If an SDK is replaced or updated, the change stays in one file.

3. **SDKs are initialized in `App/` at launch.** Feature modules never initialize or configure an SDK themselves.

4. **User identification is triggered from `Session` or `AppCoordinator` after login.** Feature modules never call identify on an SDK directly.

5. **If a feature needs to log, track, or report something, it uses the Core protocol for that concern.** For example: use `Core/Logging` to log an error, not `LCQLog` directly.

6. **When adding a new SDK, add it to this document** with its purpose, wrapper location, and who uses it.

---

## Current Violations

These SDKs are leaking outside their intended wrapper and need to be cleaned up as part of the migration.

| SDK | Violation | Fix |
|---|---|---|
| **LuciqSDK** | Imported directly in 6 feature files for logging via `LCQLog.log()` | `Core/Logging` wraps LuciqSDK. Features use the logging protocol only. |
| **Auth0** | Types leak into `AuthenticationViewModel` and login error types | `Auth0Repository` is the only file that imports Auth0. Clara-defined error and credential types are used everywhere else. |
| **Zendesk** | Minor import in `AppDelegate` for push token forwarding | Push token forwarding moves into `Core/PushNotifications/`. |

---

## Integrations

### Luciq

Luciq is the in-app bug reporting tool. Users and internal testers can shake the device to file a bug or send feedback without leaving the app. It automatically captures a screenshot, device info, and recent network logs, and links the report to the logged-in user so there's context on the other end.

| | |
|---|---|
| **Wrapper** | `Core/Logging/LuciqManager.swift` |
| **Initialized** | At app launch and on country change |
| **User identification** | After login — user ID, name, and email |
| **Used by** | QA, internal testers, and end users in production |
| **Owner** | iOS team |

---

### Thales D1

Thales powers the Add to Wallet feature. It handles the secure communication between the app and the card issuer to provision digital card credentials onto the device — including the cryptographic handshake that makes a digital card trusted by Apple Pay. Clara has a separate issuer ID per country (MX, BR, CO) and per environment (staging, production).

| | |
|---|---|
| **Wrapper** | `Core/Wallet/ThalesManager.swift` |
| **Initialized** | On demand when the user starts the Add to Wallet flow |
| **User identification** | Not applicable |
| **Used by** | Cards team via the Add to Wallet feature |
| **Owner** | iOS team. Cards team consumes the flow. |

---

### Sift

Sift runs silently in the background and collects device signals to build a risk score for the current session. It helps Clara detect suspicious activity like account takeover or fraudulent card usage. Feature teams don't interact with it — it just runs.

| | |
|---|---|
| **Wrapper** | `Core/Security/SiftManager.swift` |
| **Initialized** | At app launch |
| **User identification** | After login with user ID. Cleared on logout. |
| **Used by** | iOS team only. No direct usage by feature areas. |
| **Owner** | iOS team |

---

### Customer.io

Customer.io handles push notification delivery. The backend sends events to Customer.io, which triggers push notifications to the device. It also tracks device attributes automatically. The app's job is to register the push token and let the backend handle the rest.

| | |
|---|---|
| **Wrapper** | `Core/PushNotifications/CustomerIOManager.swift` |
| **Initialized** | At app launch |
| **User identification** | Handled server-side. The app registers the push token; Customer.io links the device to the user via the backend. |
| **Used by** | iOS team owns the integration. Push content and triggers are defined by the backend and product teams. |
| **Owner** | iOS team |

---

### Zendesk

Zendesk powers the in-app support chat. When a user contacts Clara support, they're talking to a support agent through Zendesk. The session is authenticated with a JWT token fetched from the Clara backend so the agent knows which user they're helping. Each country (MX, BR, CO) has its own support channel so queues stay separated by market.

| | |
|---|---|
| **Wrapper** | `Core/Support/ZendeskManager.swift` |
| **Initialized** | After login, configured with the channel key for the user's country |
| **User identification** | After login via a JWT token from the Clara backend. Cleared on logout. |
| **Used by** | Account team surfaces the entry point in the Profile screen. iOS team owns the integration. |
| **Owner** | iOS team |

---

### LaunchDarkly

LaunchDarkly is the feature flag service. It lets the team turn features on or off without shipping a new app version — per country, per user segment, or for internal employees only. It also controls the minimum supported app version to force users to update when needed.

| | |
|---|---|
| **Wrapper** | `Core/FeatureFlags/RemoteConfigurationManager.swift` |
| **Initialized** | At app launch with an anonymous context |
| **User identification** | After login to associate flags with the authenticated user and their country |
| **Used by** | All teams consume flags through `RemoteConfigurationManager`. No team imports LaunchDarkly directly. |
| **Owner** | iOS team owns the integration and flag definitions. Each team owns the flags for their domain. |

---

### Auth0

Auth0 handles login. It validates user credentials, returns a token used to authenticate all subsequent API calls, and manages the token lifecycle including refresh. Passwordless login runs through Auth0 as well. No other team touches it.

| | |
|---|---|
| **Wrapper** | `Modules/Auth/Shared/Auth0Repository.swift` |
| **Initialized** | Not initialized at launch. Invoked on demand during login. |
| **User identification** | Not applicable. Auth0 is the identity provider itself. |
| **Used by** | Auth team exclusively. |
| **Owner** | Auth team |

---

### Lokalise

Lokalise handles over-the-air localization. The app checks for updated translations at launch and downloads them in the background, so copy changes and new strings can reach users without going through App Store review. All teams benefit automatically — no one interacts with Lokalise directly.

| | |
|---|---|
| **Wrapper** | `Core/Localization/LokaliseManager.swift` |
| **Initialized** | At app launch. Checks for updates in the background. |
| **User identification** | Not applicable |
| **Used by** | All teams benefit automatically. No team interacts with Lokalise directly. |
| **Owner** | iOS team |
