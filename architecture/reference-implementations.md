# Reference Implementations

Two features are the canonical templates for the module structure. When in doubt, copy these — not the legacy features.

| Feature | Why it's a reference | Current location | Target location |
|---|---|---|---|
| **Tasks** | Smallest complete module: a list screen, a detail screen, its own `Dependencies` bundle, `Navigation`, `Store`, `Analytics`, and tests. The best starting point for a brand-new feature. | `ClaraCard/Features/Tasks/` | `Modules/Tasks/` |
| **ClaraConta** (Digital Account) | Largest module: many sub-screens, a shared `Store`, per-screen `Dependencies`, deep-link handling, and the PIX deposit / pay flows. The best reference for a feature that contains sub-features. | `ClaraCard/Features/ClaraConta/` | `Modules/ClaraConta/` |

## What to copy

- **Top-level feature folders** — `Analytics/`, `Dependencies/`, `Navigation/` (`Coordinator/`, `Factory/`, `Routes/`), `Store/`, `Screens/`.
- **Per-screen layout** — `Domain/`, `Data/`, `View/`, `ViewModel/`.
- **DI shape** — a `*Dependencies` protocol per screen, a `*DependenciesProvider`, and a `DependencyContainer+<Feature>` extension. See [Core/DI](core-di.md).
- **Navigation shape** — a `*Flow` route enum, a `*ScreenFactory`, a coordinator that owns the stack, and one `*Navigating` protocol per screen.
- **Tests** — under `ClaraCardTests/Features/<Feature>/`, using Swift Testing.

## What NOT to copy

- `Features/Reimbursement/` and `Features/Transactions/` — **mid-migration**. They still use the older `Domain/Data/Presentation` split with `Entities/`, `UseCases/`, `Mappers/`, `Logic/`, and `PreviewMocks/`. They are the work in progress, not the template.
- `Features/Users/` — contains a nested `Features/` and `Stories/` tree left over from before the migration; don't reproduce that shape.
- `ClaraCard/Stories/` — standalone legacy screen modules, being absorbed into feature modules.

## Naming note

`ClaraConta` is the module folder name, but its navigation types are prefixed `DigitalAccount` (`DigitalAccountCoordinator`, `DigitalAccountFlow`, `DigitalAccountScreenFactory`). Prefer a single prefix when you touch these files.
