# ClaraCard iOS  Architecture

---

## Overview

ClaraCard is a hybrid UIKit/SwiftUI iOS application serving users across
Mexico, Brazil, and Colombia. This document defines the target architecture,
folder structure, and the platform improvements being introduced to
standardize how the app is built as the team scales.

The team is currently 4 engineers. The structure defined here is designed
to support growth  each area of the codebase is owned by the team today
and can be handed to a dedicated team in the future without restructuring.

---

## Goals

- Give each area of the codebase clear ownership so the team can scale without restructuring
- Standardize how network calls are defined and executed across all modules
- Standardize how dependencies are created and injected to improve testability
- Make it easy to add new features without touching existing code
- Support a gradual migration from the existing codebase — nothing breaks

## Guiding Principles

- [Package by Feature, Not by Layer](principles/package-by-feature.md) — why the folder structure follows domains, not technical roles, and how this connects to Conway's Law and Team Topologies
- [Simplicity First](principles/simplicity-first.md) — why we avoid over-engineering and how to recognise when complexity is justified

---

## Third Party Integrations

The app integrates with the following external SDKs and services.
All integrations are owned and maintained by the iOS team.

| SDK | Purpose |
|---|---|
| **Luciq** | Bug reporting and user feedback. Users shake device to submit bugs. Captures network logs and identifies users. Also used for internal QA workflows. |
| **Thales D1** | Digital card provisioning. Handles the secure flow for adding a Clara card to Apple Wallet. Communicates with Thales cloud services. Manages issuer IDs per country (MX, BR, CO) and environments. |
| **Sift** | Fraud detection and device intelligence. Identifies the current user to build a risk score and detect suspicious activity. |
| **Customer.io** | Push notification delivery and user data pipeline. Handles APN registration and delivery. Tracks device attributes automatically. |
| **Zendesk** | In-app customer support chat. Configured per country with different channel keys. Authenticated via JWT from the Clara backend. |
| **LaunchDarkly** | Feature flags and remote configuration. Controls rollout per country and user segment. Enables toggling features without a new release. |
| **Auth0** | Authentication provider. Handles login, token management, and user identity. |
| **Lokalise** | Over-the-air localization updates. Allows string updates without a new app release. Swizzles the main bundle to serve updated translations. |

---

## Folder Structure

```
ClaraCard/
├── Core/
│   ├── Navigation/
│   ├── DI/
│   ├── Networking/
│   ├── Storage/
│   ├── Session/
│   ├── Analytics/
│   ├── FeatureFlags/
│   │   ├── FeatureFlagProviding.swift          ← protocol
│   │   └── LaunchDarklyFlagManager.swift       ← LaunchDarkly impl
│   ├── PushNotifications/
│   │   ├── PushNotificationProviding.swift     ← protocol
│   │   └── CustomerIONotificationManager.swift ← Customer.io impl
│   ├── DeepLinking/
│   ├── Extensions/
│   ├── Localization/
│   │   ├── LocalizationProviding.swift         ← protocol
│   │   └── LokaliseLocalizationManager.swift   ← Lokalise impl
│   └── Logging/
│       ├── LogProviding.swift                  ← protocol
│       └── LuciqLogger.swift                   ← Luciq impl
│
├── Modules/
│   ├── Shared/
│   │   ├── Protocols/
│   │   ├── Components/
│   │   └── Utilities/
│   │
│   ├── Auth/
│   │   ├── Onboarding/
│   │   │   ├── Presentation/
│   │   │   ├── Model/
│   │   │   ├── Data/
│   │   │   └── Networking/
│   │   ├── Login/
│   │   │   ├── Presentation/
│   │   │   ├── Model/
│   │   │   ├── Data/
│   │   │   └── Networking/
│   │   ├── UserActivation/
│   │   ├── CountrySelection/
│   │   ├── OTPChallenge/
│   │   └── Shared/
│   │       ├── Model/
│   │       ├── Networking/
│   │       └── Flow/
│   │           ├── AuthCoordinator.swift
│   │           └── AuthRoute.swift
│   │
│   ├── Cards/
│   │   ├── CardList/           ← screen (Presentation / Model / Data / Networking)
│   │   ├── CardDetail/         ← screen
│   │   ├── PIN/                ← screen
│   │   ├── Limits/             ← screen
│   │   ├── Activation/         ← screen
│   │   └── Shared/
│   │       ├── Model/
│   │       │   └── Card.swift
│   │       ├── Networking/
│   │       │   └── CardsService.swift
│   │       └── Flow/
│   │           ├── CardsCoordinator.swift
│   │           └── CardsRoute.swift
│   │
│   ├── Transactions/
│   │   ├── TransactionList/        ← screen (Presentation / Model / Data / Networking)
│   │   ├── TransactionDetail/      ← screen
│   │   ├── Filters/                ← screen
│   │   ├── Labels/                 ← screen
│   │   ├── InvoiceSuggestions/     ← screen
│   │   ├── ReportTransaction/      ← screen
│   │   ├── SuspiciousTransaction/  ← screen
│   │   └── Shared/
│   │       ├── Model/
│   │       │   └── Transaction.swift
│   │       ├── Networking/
│   │       │   └── TransactionsService.swift
│   │       └── Flow/
│   │           ├── TransactionsCoordinator.swift
│   │           └── TransactionsRoute.swift
│   │
│   ├── Reimbursements/
│   │   ├── ExpenseList/
│   │   │   ├── Presentation/
│   │   │   ├── Model/
│   │   │   ├── Data/
│   │   │   └── Networking/
│   │   │       └── FetchExpensesEndpoint.swift
│   │   ├── ExpenseDetail/
│   │   ├── ExpenseForm/
│   │   ├── BankAccount/
│   │   ├── Attachments/
│   │   └── Shared/
│   │       ├── Model/
│   │       │   └── Expense.swift
│   │       ├── Networking/
│   │       │   └── ReimbursementsService.swift
│   │       └── Flow/
│   │           ├── ReimbursementsCoordinator.swift
│   │           └── ReimbursementsRoute.swift
│   │
│   ├── Account/
│   │   ├── Profile/
│   │   │   ├── Presentation/
│   │   │   ├── Model/
│   │   │   ├── Data/
│   │   │   └── Networking/
│   │   │       └── UpdateProfileEndpoint.swift
│   │   ├── Security/
│   │   ├── Collections/
│   │   ├── Referrals/
│   │   ├── CompanySwitch/
│   │   └── Shared/
│   │       ├── Model/
│   │       │   └── UserProfile.swift
│   │       ├── Networking/
│   │       │   └── AccountService.swift
│   │       └── Flow/
│   │           ├── AccountCoordinator.swift
│   │           └── AccountRoute.swift
│   │
│   ├── ClaraConta/             ← Digital Account (BR) — PIX deposit, transfer, pay
│   │   ├── Home/               ← screen (Presentation / Model / Data / Networking)
│   │   ├── Deposit/            ← screen
│   │   ├── Pay/                ← screen
│   │   ├── PayAmount/          ← screen
│   │   ├── PaymentReview/      ← screen
│   │   ├── SearchTransactions/ ← screen
│   │   ├── TransactionDetail/  ← screen
│   │   └── Shared/
│   │       ├── Model/
│   │       ├── Networking/
│   │       └── Flow/
│   │           ├── DigitalAccountCoordinator.swift
│   │           └── DigitalAccountFlow.swift
│   │
│   └── Tasks/
│       ├── TaskList/
│       │   ├── Presentation/
│       │   │   ├── TaskListView.swift
│       │   │   └── TaskListViewModel.swift
│       │   ├── Model/
│       │   │   └── TaskList.swift
│       │   ├── Data/
│       │   │   ├── TaskListRepositoryProtocol.swift
│       │   │   ├── TaskListRepository.swift
│       │   │   ├── TaskListDTO.swift
│       │   │   └── TaskListMapper.swift
│       │   └── Networking/
│       │       └── FetchTasksEndpoint.swift
│       ├── TaskDetail/
│       └── Shared/
│           ├── Model/
│           │   └── Task.swift
│           ├── Networking/
│           │   └── TasksService.swift
│           └── Flow/
│               ├── TasksCoordinator.swift
│               └── TasksRoute.swift
│
├── App/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── AppCoordinator.swift
│   └── AppContainer.swift
│
└── ClaraNetworking/
    ├── RequestPerformer.swift
    └── ExpectedResponseType.swift
```

---

## Reference Implementations

Two features are the canonical templates for this structure — **`Tasks`** (smallest complete module) and **`ClaraConta`** / Digital Account (largest, with sub-screens, a shared `Store`, and deep links). See [reference-implementations.md](reference-implementations.md) for what to copy and what to avoid.

---

## Layer Responsibilities

Each sub-feature follows the same internal structure.


---

## Core Modules

Detailed documentation for each Core module lives in its own file:

- [Core/Networking](core-networking.md)
- [Core/DI — Dependency Injection](core-di.md)
- [Core/FeatureFlags](core-feature-flags.md)
- [Core/Logging](core-logging.md)
