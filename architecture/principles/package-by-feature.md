# Package by Feature, Not by Layer

---

## The Decision

ClaraCard is organised by **feature** (domain), not by **layer** (technical role).

This means the folder structure follows what the code *does*, not what *type* of file it is.

```
// Package by layer — what we are NOT doing
├── Views/
│   ├── CardListView.swift
│   ├── TaskListView.swift
│   └── TransactionListView.swift
├── ViewModels/
│   ├── CardListViewModel.swift
│   ├── TaskListViewModel.swift
│   └── TransactionListViewModel.swift
├── Repositories/
│   ├── CardListRepository.swift
│   ├── TaskListRepository.swift
│   └── TransactionListRepository.swift

// Package by feature — what we ARE doing
├── Cards/
│   ├── CardList/
│   │   ├── Presentation/   ← View + ViewModel
│   │   ├── Model/
│   │   ├── Data/           ← Repository + DTO + Mapper
│   │   └── Networking/
├── Tasks/
│   ├── TaskList/
│   │   ├── Presentation/
│   │   ├── Model/
│   │   ├── Data/
│   │   └── Networking/
```

---

## Why Team Topologies

Team Topologies (Skelton & Pais) describes four team types. The one relevant here is the **stream-aligned team**: a team aligned to a flow of work from a single domain Cards, Transactions, Auth  capable of delivering value end-to-end without depending on other teams.

For that to work, the codebase must match. A stream-aligned team needs to own a vertical slice: the UI, the business logic, the data access, and the network calls for their domain. If the code is split by layer, the team cannot move independently every feature requires touching shared folders owned by no one.

Package by feature is the prerequisite for stream-aligned teams. The folder structure is the foundation that makes autonomous ownership possible.

---

## Why Large Codebase Organisation

In a large codebase, package by layer breaks down for three reasons:

Package by feature solves all three:

| Problem | Layer | Feature |
|---|---|---|
| Discovery is hard | Scattered across folders | Everything for a feature is co-located |
| Ownership is unclear | Nobody owns `ViewModels/` | A team or engineer owns `Cards/` |
| Changes have wide blast radius | Wide  touches all features | Narrow  contained to one module |
