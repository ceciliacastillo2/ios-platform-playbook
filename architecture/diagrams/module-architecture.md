# ClaraCard  Module Architecture

How the app is layered and how feature modules are structured internally.
Use this to onboard engineers and align on where new code belongs.

---

## 1 · Core vs Modules

```mermaid
graph TB
  APP["App Entry\nAppDelegate · SceneDelegate · AppCoordinator · AppContainer"]

  subgraph CORE["Core  —  shared infrastructure, no feature logic"]
    direction LR
    Nav["Navigation"]
    DI["DI"]
    Net["Networking"]
    Storage["Storage"]
    Session["Session"]
    FF["FeatureFlags"]
    Push["PushNotifications"]
    DL["DeepLinking"]
    Ext["Extensions"]
    Loc["Localization"]
    Log["Logging"]
  end

  subgraph SHARED["Modules / Shared  —  reusable building blocks, no business logic"]
    direction LR
    Proto["Protocols"]
    Comp["Components"]
    Utils["Utilities"]
  end

  subgraph MODULES["Feature Modules  —  each owns a domain end to end"]
    direction LR
    Auth["Auth"]
    Cards["Cards"]
    Tasks["Tasks"]
    Transactions["Transactions"]
    Reimbursements["Reimbursements"]
    Account["Account"]
  end

  API[("Clara Backend API")]

  APP --> CORE
  APP --> MODULES
  MODULES --> CORE
  MODULES --> SHARED
  CORE --> API

  style CORE fill:#dbeafe,stroke:#3b82f6,color:#000
  style SHARED fill:#fef9c3,stroke:#ca8a04,color:#000
  style MODULES fill:#dcfce7,stroke:#16a34a,color:#000
  style APP fill:#f3e8ff,stroke:#9333ea,color:#000
  style Nav fill:#eff6ff,stroke:#3b82f6,color:#000
  style DI fill:#eff6ff,stroke:#3b82f6,color:#000
  style Net fill:#eff6ff,stroke:#3b82f6,color:#000
  style Storage fill:#eff6ff,stroke:#3b82f6,color:#000
  style Session fill:#eff6ff,stroke:#3b82f6,color:#000
  style FF fill:#eff6ff,stroke:#3b82f6,color:#000
  style Push fill:#eff6ff,stroke:#3b82f6,color:#000
  style DL fill:#eff6ff,stroke:#3b82f6,color:#000
  style Ext fill:#eff6ff,stroke:#3b82f6,color:#000
  style Loc fill:#eff6ff,stroke:#3b82f6,color:#000
  style Log fill:#eff6ff,stroke:#3b82f6,color:#000
  style Proto fill:#fefce8,stroke:#ca8a04,color:#000
  style Comp fill:#fefce8,stroke:#ca8a04,color:#000
  style Utils fill:#fefce8,stroke:#ca8a04,color:#000
  style Auth fill:#f0fdf4,stroke:#16a34a,color:#000
  style Cards fill:#f0fdf4,stroke:#16a34a,color:#000
  style Tasks fill:#f0fdf4,stroke:#16a34a,color:#000
  style Transactions fill:#f0fdf4,stroke:#16a34a,color:#000
  style Reimbursements fill:#f0fdf4,stroke:#16a34a,color:#000
  style Account fill:#f0fdf4,stroke:#16a34a,color:#000
  style API fill:#dbeafe,stroke:#3b82f6,color:#000
```

**Core** holds everything that is not specific to a feature networking, DI, navigation, session, and all third-party SDK wrappers. No feature logic lives here.

**Modules / Shared** holds protocols, UI components, and utilities that are used by two or more modules but do not belong to any one of them.

**Feature Modules** each own a domain end to end from the screen down to the API call. No module imports from another module.

---

## 2 · Layer responsibilities

| Layer | Lives in | Responsibility |
|---|---|---|
| `Flow/` | `Module/Shared/Flow/` | Coordinator owns navigation. Route defines all destinations within the module. |
| `Presentation/` | `SubFeature/Presentation/` | View and ViewModel only. No networking, no direct data access. |
| `Model/` | `SubFeature/Model/` | Domain entity. Pure Swift, no frameworks. Shared models move to `Module/Shared/Model/`. |
| `Data/` | `SubFeature/Data/` | RepositoryProtocol (contract), Repository (implementation), DTO (API shape, never exposed outside Data), Mapper (DTO → Model). |
| `Networking/` | `SubFeature/Networking/` | One endpoint file per API call. The shared service lives at `Module/Shared/Networking/`. |
