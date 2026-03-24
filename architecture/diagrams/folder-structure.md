# ClaraCard  Folder Structure

Every feature module owns its full vertical slice: screens, view models, models, repositories, and coordinator.
No module reaches into another module's internals.

---

## Modules

| Module | Screens | Coordinator |
|---|---|---|
| `Auth` | Onboarding · Login · UserActivation · CountrySelection · OTPChallenge | `AuthCoordinator` |
| `Cards` | CardList · CardDetail · PIN · Limits · Activation | `CardsCoordinator` |
| `Transactions` | TransactionList · TransactionDetail · Filters · Labels · InvoiceSuggestions · ReportTransaction · SuspiciousTransaction | `TransactionsCoordinator` |
| `Reimbursements` | ExpenseList · ExpenseDetail · ExpenseForm · BankAccount · Attachments | `ReimbursementsCoordinator` |
| `Account` | Profile · Security · Collections · Referrals · CompanySwitch | `AccountCoordinator` |
| `Tasks` | TaskList · TaskDetail | `TasksCoordinator` |

---

## 1 · App layers

```mermaid
graph TB
  APP["App/\nEntry point · Root coordinator bootstrap"]

  subgraph CORE["Core/  —  infrastructure, no feature logic"]
    CORE_D["Navigation · DI · Networking · Storage · Session\nAnalytics · FeatureFlags · PushNotifications · DeepLinking\nExtensions · Localization · Logging"]
  end

  subgraph SHARED["Modules/Shared/  —  reusable building blocks"]
    SHARED_D["Protocols · Components · Utilities"]
  end

  subgraph MODULES["Modules/  —  feature modules"]
    MOD_D["Cards · Tasks · Identity · Onboarding\nTransactions · Reimbursements · Account"]
  end

  APP --> CORE
  APP --> MODULES
  MODULES --> CORE
  MODULES --> SHARED

  style CORE fill:#dbeafe,stroke:#3b82f6
  style SHARED fill:#fef9c3,stroke:#ca8a04
  style MODULES fill:#dcfce7,stroke:#16a34a
  style APP fill:#f3e8ff,stroke:#9333ea
```

---

## 2 · Feature modules

Each module owns its screens and is isolated from other modules.
The module boundary (coordinator + shared model) is separate from the screens it contains.

```mermaid
graph LR

  subgraph CardsModule["Cards Module"]
    direction TB
    CardsShared["Router/\nCardsCoordinator · CardsRoute · Card.swift · CardsService"]

    subgraph CardsScreens["Screens"]
      direction LR
      CL["CardList\nCardListView\nCardListViewModel"]
      CD["CardDetail\nCardDetailView\nCardDetailViewModel"]
      PIN["PIN\nShowPINView\nChangePINView"]
      LIM["Limits\nCardLimitView\nRequestLimitIncreaseView"]
      ACT["Activation\nActivateCardView\nActivateCardSuccessView"]
    end

    CardsShared --> CardsScreens
  end

  subgraph TasksModule["Tasks Module"]
    direction TB
    TasksShared["Router/\nTasksCoordinator · TasksRoute · Task.swift · TasksService"]

    subgraph TasksScreens["Screens"]
      direction LR
      TL["TaskList\nTaskListView\nTaskListViewModel"]
      TD["TaskDetail\nTaskDetailView\nTaskDetailViewModel"]
    end

    TasksShared --> TasksScreens
  end

  style CardsModule fill:#f0fdf4,stroke:#16a34a,color:#111
  style CardsShared fill:#dcfce7,stroke:#16a34a,color:#111
  style CardsScreens fill:#dbeafe,stroke:#3b82f6,color:#111
  style CL fill:#eff6ff,stroke:#3b82f6,color:#111
  style CD fill:#eff6ff,stroke:#3b82f6,color:#111
  style PIN fill:#eff6ff,stroke:#3b82f6,color:#111
  style LIM fill:#eff6ff,stroke:#3b82f6,color:#111
  style ACT fill:#eff6ff,stroke:#3b82f6,color:#111
  style TasksModule fill:#f0fdf4,stroke:#16a34a,color:#111
  style TasksShared fill:#dcfce7,stroke:#16a34a,color:#111
  style TasksScreens fill:#dbeafe,stroke:#3b82f6,color:#111
  style TL fill:#eff6ff,stroke:#3b82f6,color:#111
  style TD fill:#eff6ff,stroke:#3b82f6,color:#111
```

---

## 3 · Internal pattern every module follows

Dependencies flow in from `Core/DI` — no class creates its own dependencies.

```mermaid
graph TB
  DI["Core/DI\nCentralised container\nRegisters and resolves all dependencies"]

  subgraph Module["Feature Module"]
    F["Flow/\nCoordinator · Route\nDependencies provided by DI"]
    P["Presentation/\nView · ViewModel\nDepends on RepositoryProtocol via DI"]
    M["Model/\nDomain entity\nPure Swift · no frameworks · no DI needed"]
    D["Data/\nRepositoryProtocol ← resolved by DI\nRepository ← registered in DI container\nDTO · Mapper"]
    N["Networking/\nEndpoints\nService resolved via DI"]
    S["Shared/\nService · shared models\nRegistered once in DI · shared across sub-features"]
  end

  DI -->|"Injects Coordinator"| F
  DI -->|"Injects Repository"| P
  DI -->|"Injects Service"| S
  F -->|"Creates & owns"| P
  P -->|"Depends on protocol"| D
  D -->|"Maps to"| M
  D -->|"Uses"| N
  N -->|"Uses"| S

  style DI fill:#fce7f3,stroke:#db2777
  style Module fill:#f8fafc,stroke:#94a3b8
  style F fill:#f3e8ff,stroke:#9333ea
  style P fill:#dbeafe,stroke:#3b82f6
  style M fill:#fef9c3,stroke:#ca8a04
  style D fill:#dcfce7,stroke:#16a34a
  style N fill:#ffe4e6,stroke:#e11d48
  style S fill:#f1f5f9,stroke:#64748b
```

**Key rules:**
- `Core/DI` is the only place dependencies are created never inside a class
- ViewModels depend on a `RepositoryProtocol`, never on a concrete `Repository` this makes them independently testable
- Dependencies are provided by the DI container, not created or looked up by the class that needs them
- `Service` (network client) is registered once in DI and shared across all repositories within the module
