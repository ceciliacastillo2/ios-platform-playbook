# ClaraCard C4 Diagrams

## Level 1 · System Context

Who interacts with ClaraCard and what external systems it depends on.

```mermaid
graph LR
  USER(["👤 Cardholder"])

  APP["🏦 ClaraCard iOS App
  ─────────────────────
  Auth · Cards · Tasks
  Transactions · Reimbursements · Account"]

  subgraph BACKEND["Clara Infrastructure"]
    API["Clara Backend API
    ──────────────────
    REST / HTTPS
    Core business logic
    User & session data
    Card operations
    Transactions"]
  end

  subgraph THIRD_PARTY["Third Party Services · all wrapped in Core/ · never imported directly by feature modules"]
    direction TB
    AUTH0["Auth0
    Identity · Login · Tokens"]
    CIO["Customer.io
    Push notifications"]
    APNS["APNs
    Apple push delivery"]
    LD["LaunchDarkly
    Feature flags"]
    LOK["Lokalise
    OTA localization"]
    ZD["Zendesk
    Support chat"]
    LCQ["Luciq
    Bug reporting"]
    SIFT["Sift
    Fraud detection"]
    THALES["Thales D1
    Apple Wallet provisioning"]
  end

  USER -->|"Uses"| APP
  APP -->|"All API calls"| API
  APP -->|"Via Core wrappers"| THIRD_PARTY

  style USER fill:#f3e8ff,stroke:#9333ea,color:#000
  style APP fill:#f3e8ff,stroke:#9333ea,color:#000
  style BACKEND fill:#dbeafe,stroke:#3b82f6
  style API fill:#dbeafe,stroke:#3b82f6,color:#000
  style THIRD_PARTY fill:#f8fafc,stroke:#94a3b8
  style AUTH0 fill:#ede9fe,stroke:#7c3aed,color:#000
  style CIO fill:#ffedd5,stroke:#ea580c,color:#000
  style APNS fill:#ffedd5,stroke:#ea580c,color:#000
  style LD fill:#dcfce7,stroke:#16a34a,color:#000
  style LOK fill:#dcfce7,stroke:#16a34a,color:#000
  style ZD fill:#fef9c3,stroke:#ca8a04,color:#000
  style LCQ fill:#fef9c3,stroke:#ca8a04,color:#000
  style SIFT fill:#ffe4e6,stroke:#e11d48,color:#000
  style THALES fill:#ccfbf1,stroke:#0d9488,color:#000
```

### External systems

| Category | System | Description |
|---|---|---|
| **Backend** | Clara Backend API | Core business logic and data layer. All feature modules reach the backend exclusively through `Core/Networking`. |
| **Identity** | Auth0 | Authentication provider. Handles login, passwordless flows, token issuance, and refresh. The app never stores credentials — Auth0 owns the full identity lifecycle. |
| **Notifications** | Customer.io | Manages push notification delivery and tracks device attributes. The backend sends events to Customer.io which triggers pushes to the device via APNs. |
| **Notifications** | APNs | Apple's push delivery infrastructure. The app receives all push notifications through APNs. Customer.io is the upstream system that sends to APNs. |
| **Feature Control** | LaunchDarkly | Feature flag and remote configuration service. Allows features to be toggled per country, per user segment, or for internal employees without a new app release. |
| **Feature Control** | Lokalise | Over-the-air localization. Serves updated translation strings at launch so copy changes ship without going through App Store review. |
| **Support & Ops** | Zendesk | In-app customer support chat. Configured with a per-country channel key so support queues are separated by market. Authenticated via a JWT from the Clara backend. |
| **Support & Ops** | Luciq | In-app bug reporting and QA feedback tool. Users and testers shake the device to capture a screenshot, device info, and recent network logs and submit a report. |
| **Security** | Sift | Fraud detection SDK. Collects device signals silently in the background to build a risk score for the current session. Used to detect suspicious card activity and account takeover. |
| **Wallet** | Thales D1 | Digital card provisioning SDK. Handles the cryptographic flow that provisions a Clara card as a trusted payment credential in Apple Wallet. Configured per country and environment. |

---

## Level 2 · Container

### 2a · App layers and feature modules

How the app is structured internally — entry point, core infrastructure, shared utilities, and feature modules. Feature modules reach the backend exclusively through `ClaraNetworking`; no module calls the API directly.

```mermaid
graph TB
  User(["👤 Cardholder"])

  subgraph ClaraCard["ClaraCard iOS App"]
    APP["App Entry
    ──────────────
    AppDelegate · SceneDelegate
    AppCoordinator · AppContainer"]

    subgraph CORE["Core  —  shared infrastructure, no feature logic"]
      direction LR
      INFRA["Navigation · DI · Session
      Storage · DeepLinking
      Analytics · Extensions · Localization"]
      WRAPPERS["SDK Wrappers
      FeatureFlags · PushNotifications
      Logging · Support · Security · Wallet"]
    end

    subgraph SHARED["Shared"]
      SHARED_D["Protocols · Components · Utilities"]
    end

    subgraph MODULES["Feature Modules  —  each defines its own endpoints"]
      direction LR
      Cards["Cards
      Card List · Card Detail
      PIN · Limits · Activation"]
      Tasks["Tasks
      Task List · Task Detail"]
      Auth["Auth
      Onboarding · Login
      Activation · OTP · Country"]
      Transactions["Transactions
      Own set of screens"]
      Reimbursements["Reimbursements
      Own set of screens"]
      Account["Account
      Own set of screens"]
    end

    NET["ClaraNetworking  —  internal Swift package
    ──────────────────────────────────────────────
    RequestPerformer · WebSocketPerformer
    Router · WebSocketRouter · ClaraNetworkingError"]
  end

  API["Clara Backend API
  ──────────────────
  REST / HTTPS · WebSocket
  All feature data"]

  User --> APP
  APP --> CORE
  APP --> MODULES
  MODULES --> CORE
  MODULES --> SHARED
  MODULES -->|"Router enums"| NET
  NET -->|"HTTP · WebSocket"| API

  style APP fill:#f3e8ff,stroke:#9333ea,color:#000
  style CORE fill:#dbeafe,stroke:#3b82f6
  style INFRA fill:#eff6ff,stroke:#3b82f6,color:#000
  style WRAPPERS fill:#eff6ff,stroke:#3b82f6,color:#000
  style NET fill:#bfdbfe,stroke:#1d4ed8,color:#000
  style SHARED fill:#fef9c3,stroke:#ca8a04
  style SHARED_D fill:#fefce8,stroke:#ca8a04,color:#000
  style MODULES fill:#dcfce7,stroke:#16a34a
  style Cards fill:#f0fdf4,stroke:#16a34a,color:#000
  style Tasks fill:#f0fdf4,stroke:#16a34a,color:#000
  style Auth fill:#f0fdf4,stroke:#16a34a,color:#000
  style Transactions fill:#f0fdf4,stroke:#16a34a,color:#000
  style Reimbursements fill:#f0fdf4,stroke:#16a34a,color:#000
  style Account fill:#f0fdf4,stroke:#16a34a,color:#000
  style ClaraCard fill:#f8fafc,stroke:#64748b
  style API fill:#dbeafe,stroke:#3b82f6,color:#000
```

---

### 2b · Core SDK wrappers

Every third party SDK has exactly one wrapper in Core. Feature modules never import an SDK directly they depend on the wrapper protocol via DI.

```mermaid
graph LR
  subgraph CORE["Core / SDK Wrappers"]
    direction TB
    AUTH0W["Auth0Repository
    protocol: AuthProviding"]
    PUSHW["CustomerIOManager
    protocol: PushNotificationProviding"]
    FLAGSW["LaunchDarklyFlagManager
    protocol: FeatureFlagProviding"]
    SUPPORTW["ZendeskManager
    protocol: SupportProviding"]
    FRAUDW["SiftManager
    protocol: FraudDetectionProviding"]
    WALLETW["ThalesManager
    protocol: WalletProviding"]
    LOGGINGW["LuciqLogger
    protocol: LogProviding"]
    LOCALEW["LokaliseLocalizationManager
    protocol: LocalizationProviding"]
  end

  subgraph SDKS["Third Party SDKs"]
    direction TB
    A["Auth0"]
    B["Customer.io"]
    C["LaunchDarkly"]
    D["Zendesk"]
    E["Sift"]
    F["Thales D1"]
    G["Luciq"]
    H["Lokalise"]
  end

  AUTH0W --> A
  PUSHW --> B
  FLAGSW --> C
  SUPPORTW --> D
  FRAUDW --> E
  WALLETW --> F
  LOGGINGW --> G
  LOCALEW --> H

  style CORE fill:#dbeafe,stroke:#3b82f6
  style SDKS fill:#f8fafc,stroke:#94a3b8
  style AUTH0W fill:#eff6ff,stroke:#3b82f6,color:#000
  style PUSHW fill:#eff6ff,stroke:#3b82f6,color:#000
  style FLAGSW fill:#eff6ff,stroke:#3b82f6,color:#000
  style SUPPORTW fill:#eff6ff,stroke:#3b82f6,color:#000
  style FRAUDW fill:#eff6ff,stroke:#3b82f6,color:#000
  style WALLETW fill:#eff6ff,stroke:#3b82f6,color:#000
  style LOGGINGW fill:#eff6ff,stroke:#3b82f6,color:#000
  style LOCALEW fill:#eff6ff,stroke:#3b82f6,color:#000
  style A fill:#ede9fe,stroke:#7c3aed,color:#000
  style B fill:#ffedd5,stroke:#ea580c,color:#000
  style C fill:#dcfce7,stroke:#16a34a,color:#000
  style D fill:#fef9c3,stroke:#ca8a04,color:#000
  style E fill:#ffe4e6,stroke:#e11d48,color:#000
  style F fill:#ccfbf1,stroke:#0d9488,color:#000
  style G fill:#fef9c3,stroke:#ca8a04,color:#000
  style H fill:#dcfce7,stroke:#16a34a,color:#000
```
