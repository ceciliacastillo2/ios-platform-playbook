# iOS Technical Improvement Playbook

**Audience:** Engineering leadership and startup founders
**Goal:** A prioritized, phased plan to move the iOS codebase from its current state to a production-grade foundation — without a big-bang rewrite.

---

## The Core Argument

Most of the problems listed below are symptoms of one root cause: **the codebase has no contracts between its parts**. Modules talk directly to concrete implementations. There is no agreed boundary between what a module does and how it does it. As a result:

- You cannot test anything in isolation
- You cannot safely move ownership between teams
- You cannot refactor without fear of breaking unrelated things
- You cannot enforce visual consistency without a shared design language

Fix the contracts first. Everything else gets easier.

---

## Priority Matrix — Value vs Effort

```
HIGH VALUE
    │
    │   [1] Protocol adoption ──────────── root cause, high value, medium effort
    │   [2] Design system (tokens/colors) ─ root cause, high value, low-medium effort
    │   [3] Release automation ─────────── fastest visible win, medium effort
    │
    │   [4] Unit tests ──────────────────── unlocked by [1], high value, medium effort
    │   [5] Snapshot tests ───────────────── unlocked by [2], high value, low effort
    │   [6] Domain ownership ────────────── unlocked by [1], high value, high effort
    │
    │   [7] Composite endpoints ──────────── joint initiative, high value, high effort
    │   [8] Performance ──────────────────── reactive until [1] done, medium value
    │   [9] Architecture documentation ───── enables onboarding and safe refactoring
    │
LOW VALUE
    └──────────────────────────────────────────────────────────────────
         LOW EFFORT                                          HIGH EFFORT
```

### Root Causes vs Symptoms

| Problem | Type | Blocks |
|---|---|---|
| No protocols / interfaces | **Root cause** | Testing, ownership, safe refactoring |
| No design system (colors, tokens, components) | **Root cause** | Visual consistency, snapshot testing, design handoff |
| No unit tests | Symptom of (1) | Confidence to ship, regression safety |
| No snapshot tests | Symptom of (2) | UI regression safety, design drift detection |
| No domain ownership | Symptom of (1) | Team autonomy, QA clarity |
| Manual releases | Independent problem | Engineering time, release risk |
| Performance issues | Symptom of missing boundaries | Optimization without a map is guesswork |
| No composite endpoints | Joint initiative | Over-fetching, round-trip latency |
| No architecture documentation | Compounding risk | Onboarding, migration planning, domain split |

---

## Problem Areas in Detail

### 1. No protocols / interfaces
Modules are tightly coupled to concrete implementations. There is no contract between what a module needs and how that need is fulfilled. This makes it impossible to test in isolation, impossible to swap implementations, and hard to understand what any given module actually depends on.

### 2. No design system — colors and tokens
The app has no shared source of truth for colors, typography, spacing, or component states. Values are hardcoded or duplicated across screens. When the design team changes a brand color, it requires a manual audit of the entire codebase. There is no way to enforce consistency automatically.

This also blocks snapshot testing: snapshots taken against hardcoded values are brittle and break whenever any value changes in any file, rather than when the design token itself changes.

### 3. No unit tests
The absence of protocols means the absence of mocks. Without mocks, unit tests cannot isolate a single behavior — they become integration tests at best, impossible at worst. There is no safety net for refactoring and no signal when a change breaks existing behavior.

### 4. No snapshot tests
Without a design system, snapshot tests would be brittle. With a design system in place, snapshot tests become a powerful guard: any unintended visual change — a color shift, a layout regression, a font size change — is caught before it reaches users.

### 5. Manual releases
The release process depends on individual engineers following manual steps. There is no automated build, no automated test run on PR, and no one-button path to TestFlight or the App Store. This creates release risk, slows down the team, and makes it impossible to ship confidently on a regular cadence.

### 6. No domain ownership
There are no clear module boundaries and no team assigned to each domain. When a bug appears in Cards, everyone needs to understand the entire app to fix it safely. Cross-domain changes are the norm rather than the exception.

### 7. Performance issues
Without module boundaries and without a map of data flow, performance problems are hard to locate and risky to fix. The team knows there are slow screens but has no systematic way to isolate where the time is being spent or to verify that a fix worked without breaking something else.

### 8. No composite endpoints
The backend serves generic endpoints that return more data than needed or require multiple round trips to assemble a single screen. This is a mobile-specific cost — battery, latency, and data usage — that requires a joint initiative with the backend team to address.

### 9. No architecture documentation
There is no diagram showing how modules relate to each other. No one on the team can fully explain the data flow for a key user journey. Onboarding a new engineer requires weeks of exploration. Refactoring is risky because no one agrees on the boundaries.

---

## Phased Roadmap

### Phase 1 — Foundations
*Goal: Create the conditions for safe change. No production risk. No big refactors.*

**1. Establish the design system**
Define the token set: colors (semantic names, not hex values), typography scale, spacing scale, corner radii, elevation. Implement them as a Swift package or a dedicated module. All new UI work uses tokens. No new hardcoded values are merged.

This is the prerequisite for snapshot testing and for a consistent design handoff process.

Deliverable: A `DesignSystem` module with a documented token set. A PR convention that rejects hardcoded visual values.

**2. Extract protocols at the most painful boundaries**
Pick the two or three repositories or services referenced most across the codebase. Extract a protocol for each. Do not rename, do not move files, do not change behaviour. The concrete type still exists — it now sits behind a protocol.

This is the first testability seam. Nothing breaks in production. The team learns the pattern.

**3. Automate the release pipeline**
Set up CI/CD for build, test (even with zero tests today), and distribution. This is the fastest change visible to leadership — releases stop being manual events.

Deliverable: Automated build on every PR. One-button release to TestFlight.

---

### Phase 2 — Structure
*Goal: Establish module boundaries. Start the testing culture. Enforce the design language.*

**4. Write the first snapshot tests**
With the design system in place, add snapshot tests for the highest-visibility screens. Any color, layout, or component change that deviates from the approved token renders as a failing test. Design drift is caught in CI, not in production.

**5. Write the first unit tests**
With protocols in place from Phase 1, write tests for the newly abstracted repositories. Start with the highest-risk domain. Build the convention — test file structure, mock naming, what counts as a unit.

**6. Expand protocol adoption systematically**
Work domain by domain. One initiative per domain: extract protocols, write tests, assign ownership. This is how domain boundaries get drawn — not by a big-bang reorganisation, but by progressively adding contracts.

**7. Document the architecture**
Map the current module structure and data flow for the two or three most critical user journeys. Draw the target layered architecture (see System Design section). This document becomes the reference every PR is reviewed against and the onboarding guide for every new engineer.

**8. Raise composite endpoints with backend**
Frame this as a product performance initiative. Identify the screens with the most round trips. Quantify the latency. Propose a joint spike with the backend team to design aggregated responses for those screens.

---

### Phase 3 — Optimization
*Goal: With a mapped, tested, owned codebase — optimize with confidence.*

**9. Performance profiling**
With module boundaries and tests in place, performance problems can be isolated to a layer and fixed without fear. Instrument the critical paths identified earlier.

**10. Domain autonomy**
Teams own their domains end to end. Cross-domain changes require explicit protocol contracts, not implicit knowledge of implementation details.

**11. Enforce the architecture automatically**
Add linting rules or build-time checks that enforce the dependency rule (inner layers do not import outer layers). Architecture violations become CI failures, not code review debates.

---

## System Design

### Layered Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                  │
│         ViewModels · Views · Navigation              │
│         Depends on: Domain protocols only            │
├─────────────────────────────────────────────────────┤
│                   Domain Layer                       │
│         Use Cases · Domain Models · Protocols        │
│         Depends on: nothing outside this layer       │
├─────────────────────────────────────────────────────┤
│                    Data Layer                        │
│         Repositories · Networking · Storage          │
│         Conforms to: Domain protocols                │
├─────────────────────────────────────────────────────┤
│                 Infrastructure Layer                 │
│         URLSession · Keychain · Analytics SDK        │
│         Third-party integrations                     │
└─────────────────────────────────────────────────────┘

         DesignSystem module sits alongside all layers.
         It has no dependencies on any layer.
         All layers may import it for visual tokens.
```

**The dependency rule:** arrows point inward only. The Domain layer has no import statements referencing the Data or Presentation layers. The Presentation layer imports Domain, never Data directly.

---

### How Protocols Sit at Layer Boundaries

Each boundary is crossed through a protocol defined in the inner layer and implemented in the outer layer.

```
Presentation                Domain                    Data
────────────                ──────                    ────

TransactionViewModel ──▶  TransactionRepository  ◀── DefaultTransactionRepository
                           (protocol, owned           (concrete, lives in Data,
                            by Domain)                 imports networking internals)
```

The ViewModel depends on the protocol. It does not know — and does not care — whether the data comes from the network, a local cache, or a test mock. The Data layer conforms to the protocol. The Domain layer owns the contract.

---

### Feature Module Dependency Map

How a feature module connects to shared services without importing concrete types:

```
┌─────────────────────────────────────────────────────────────────┐
│                      Feature: Transactions                       │
│                                                                  │
│   TransactionListViewModel                                       │
│         │                                                        │
│         ├──▶ TransactionRepository (protocol) ──▶ [Data Layer]  │
│         ├──▶ AnalyticsTracking (protocol) ──▶ [Infrastructure]  │
│         └──▶ ErrorReporting (protocol) ──▶ [Infrastructure]     │
│                                                                  │
│   All three are injected at init. The ViewModel has no           │
│   import for networking, analytics SDK, or error SDK.            │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         Design System                            │
│                                                                  │
│   TransactionListView                                            │
│         │                                                        │
│         ├──▶ Color.brand.primary (token)                         │
│         ├──▶ Typography.body (token)                             │
│         └──▶ Spacing.md (token)                                  │
│                                                                  │
│   No hardcoded values. Snapshot tests lock the rendered          │
│   output. A token change is a deliberate, traceable decision.    │
└─────────────────────────────────────────────────────────────────┘
```

---

### As-Is → To-Be Migration Path

**Do not rewrite. Migrate.**

```
Step 1 — Document as-is
  Map current modules and dependencies.
  Agree on what exists. No changes yet.

Step 2 — Define to-be
  Draw target layer boundaries.
  Agree on what each module should depend on.

Step 3 — Extract protocols at the boundary
  The concrete type stays. A protocol appears in front of it.
  Callers are updated to use the protocol.
  Tests become possible.

Step 4 — Move the concrete type to the correct layer
  Only after the protocol is in place and callers are clean.
  This is safe because callers already depend on the protocol.

Step 5 — Delete what no longer belongs
  Dead code, duplicate paths, deprecated types — remove them
  once the protocol boundary makes their absence safe.
```

At no point is the app broken. At no point does a refactor sprint produce zero user-facing value. Each step ships independently.

---

## Framing for Leadership

| Initiative | Engineering framing | Business framing |
|---|---|---|
| Protocol adoption | Decouple modules via interfaces | Reduce the cost and risk of every future feature |
| Design system (tokens) | Shared color and spacing primitives | Ship UI changes once — not once per screen. Design and engineering stay in sync |
| Release automation | CI/CD pipeline | Ship faster, with less risk, with no manual steps |
| Unit tests | Test coverage from protocol boundaries | Catch regressions before users do |
| Snapshot tests | UI regression suite backed by design tokens | The app looks right on every release, automatically |
| Domain ownership | Module boundaries per team | Each team ships independently without stepping on each other |
| Composite endpoints | Aggregation layer with backend | Screens load faster — direct impact on user retention |
| Performance | Profiling and optimization | App feels faster — measurable impact on activation |
| Architecture documentation | As-is and to-be diagrams | New engineers are productive faster. Refactoring stops being a gamble |

---

## What This Is Not

- This is not a rewrite. The existing code keeps running while the new structure grows around it.
- This is not a pause on features. Each phase delivers independently.
- This is not an engineering vanity project. Every item above has a direct line to shipping speed, release confidence, or user experience.

The goal is a codebase where adding a feature does not require understanding the entire app, where a bug in one domain does not require touching three others, where the UI looks right on every release, and where the team ships on a schedule rather than on courage.
