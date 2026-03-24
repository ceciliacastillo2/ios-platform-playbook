# Third Party Integrations

---

## Overview

The app integrates with several third party SDKs to handle authentication,
fraud detection, customer support, feature flags, localization, bug reporting,
push notifications, and digital card provisioning.

All third party integrations are owned and maintained by the iOS team.
Feature areas consume the functionality through wrappers defined in `Core/`.
No feature area should import a third party SDK directly.

---

## Rules

1. **Every third party SDK must have a single wrapper in `Core/`.** The wrapper is the only file in the codebase that imports the SDK.

2. **Feature modules depend on the wrapper interface, never on SDK types.** If a SDK is replaced or updated the change is isolated to one file.

3. **SDK initialization happens in `App/` at launch.** Feature modules never initialize or configure a SDK directly.

4. **User identification calls are triggered from `Session` or `AppCoordinator` after authentication.** Feature modules never call identify on a SDK directly.

5. **If a feature needs to log, track, or report something it uses the Core protocol for that concern.** Example: to log an error use `Core/Logging`, not `LCQLog` directly.

6. **When adding a new third party SDK always add it to this document** with its purpose, wrapper location, and the teams that use it.

---

## Current Violations to Address

The following SDKs currently leak outside their intended wrapper.
These should be fixed as part of the migration to the new structure.

| SDK | Violation | Fix |
|---|---|---|
| **LuciqSDK** | Imported directly in 6 feature files for logging via `LCQLog.log()` | `Core/Logging` wraps LCQLog. Features use the logging protocol only. |
| **Auth0** | Types leak into `AuthenticationViewModel` and login error types | `Auth0Repository` is the only file that imports Auth0. Clara-defined error and credential types are used everywhere else. |
| **Zendesk** | Minor import in `AppDelegate` for push token forwarding | Push token forwarding moves into `Core/PushNotifications/`. |

---

## Integrations

### Luciq

| | |
|---|---|
| **Purpose** | In-app bug reporting and feedback tool. Allows users and internal testers to shake the device to report a bug or send feedback without leaving the app. Captures a screenshot, device information, and recent network logs automatically. Links reports to the logged-in user for context. |
| **Wrapper** | `Core/Logging/LuciqManager.swift` |
| **Initialized** | At app launch and on country change |
| **User identification** | Called after successful login with user ID, name, and email |
| **Used by** | QA and internal testers during development and beta. Also available to end users in production. |
| **Owner** | iOS team |

---

### Thales D1

| | |
|---|---|
| **Purpose** | Digital card provisioning SDK. Powers the Add to Wallet feature. Handles the secure communication between the app and the card issuer to provision digital card credentials onto the device. Manages the cryptographic process that makes a digital card trusted by Apple Pay. Clara has a separate issuer ID per country (MX, BR, CO) and per environment (staging, production). |
| **Wrapper** | `Core/Wallet/ThalesManager.swift` |
| **Initialized** | On demand when the user initiates the Add to Wallet flow |
| **User identification** | Not applicable |
| **Used by** | Cards team via the Add to Wallet feature |
| **Owner** | iOS team. Cards team consumes the flow. |

---

### Sift

| | |
|---|---|
| **Purpose** | Fraud detection and device intelligence SDK. Runs silently in the background and collects device signals to build a risk score for the current user and session. Helps Clara detect suspicious activity such as account takeover or fraudulent card usage. |
| **Wrapper** | `Core/Security/SiftManager.swift` |
| **Initialized** | At app launch |
| **User identification** | Called after successful login with user ID. Called on logout to clear the user ID. |
| **Used by** | Owned by the iOS team. No direct usage by feature areas. |
| **Owner** | iOS team |

---

### Customer.io

| | |
|---|---|
| **Purpose** | Push notification delivery and customer data platform. Delivers transactional and marketing push notifications to users. Tracks device attributes automatically. The backend sends events to Customer.io which then triggers push notifications to the app. |
| **Wrapper** | `Core/PushNotifications/CustomerIOManager.swift` |
| **Initialized** | At app launch |
| **User identification** | Handled server side. The app registers the push token and device attributes. Customer.io links the device to the user via the backend. |
| **Used by** | Owned by the iOS team. Push notification content and triggers are defined by the backend and product teams. |
| **Owner** | iOS team |

---

### Zendesk

| | |
|---|---|
| **Purpose** | In-app customer support chat. Provides the live chat experience when users contact Clara support from within the app. Authenticated via a JWT token fetched from the Clara backend so the support agent knows which Clara user they are talking to. Each country (MX, BR, CO) has its own channel so support queues are separated by market. |
| **Wrapper** | `Core/Support/ZendeskManager.swift` |
| **Initialized** | After login, configured with the channel key for the user country |
| **User identification** | Called after login using a JWT token from the Clara backend. Called on logout to invalidate the session. |
| **Used by** | Account team surfaces the entry point in the Profile screen. iOS team owns the integration. |
| **Owner** | iOS team |

---

### LaunchDarkly

| | |
|---|---|
| **Purpose** | Feature flag and remote configuration service. Allows the team to turn features on or off without releasing a new app version. Controls feature visibility per country, per user segment, or for internal employees only. Also controls the minimum supported app version to force users to update. |
| **Wrapper** | `Core/FeatureFlags/RemoteConfigurationManager.swift` |
| **Initialized** | At app launch with an anonymous context |
| **User identification** | Called after login to associate flags with the authenticated user and their country |
| **Used by** | All teams consume feature flags through `RemoteConfigurationManager`. No team imports LaunchDarkly directly. |
| **Owner** | iOS team owns the integration and flag definitions. Each team owns the flags relevant to their domain. |

---

### Auth0

| | |
|---|---|
| **Purpose** | Authentication and identity platform. Handles the login flow, validates user credentials, and returns a token used to authenticate all subsequent API calls. Supports passwordless login and manages the token lifecycle including refresh. |
| **Wrapper** | `Modules/Auth/Shared/Auth0Repository.swift` |
| **Initialized** | Not initialized at launch. Invoked on demand during login. |
| **User identification** | Not applicable. Auth0 is the identity provider itself. |
| **Used by** | Auth team exclusively. No other team imports or calls Auth0. |
| **Owner** | Auth team |

---

### Lokalise

| | |
|---|---|
| **Purpose** | Over-the-air localization and translation management. Allows the team to update in-app text strings without releasing a new app version. The app checks for updated translations at launch and downloads them in the background. Copy changes, error messages, and new translated strings can be shipped to users immediately without App Store review. |
| **Wrapper** | `Core/Localization/LokaliseManager.swift` |
| **Initialized** | At app launch. Checks for updates in the background. |
| **User identification** | Not applicable |
| **Used by** | All teams benefit automatically. No team interacts with Lokalise directly. |
| **Owner** | iOS team |
