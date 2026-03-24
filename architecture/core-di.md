# Core/DI — Dependency Injection

## Goal

Each module declares exactly what it needs through a protocol. The main app container conforms to those protocols and wires everything together. No module knows about the container — modules are fully decoupled from the app and independently testable.

---

## Design

### 1. Module defines what it needs — `ExternalDependencies` protocol

Each module owns a protocol listing its external dependencies. This is the only contract between the module and the outside world.

```swift
// Features/Cards/CardsDependencies.swift

protocol CardsExternalDependencies {
    var session: SessionProviding { get }
    var featureFlags: FeatureFlagProviding { get }
    var bugReporter: BugReportLoggable { get }
}
```

### 2. Module builds its own internal dependencies

The module uses the external protocol to construct its internal dependencies. Repositories and loggers are created here — not by the app.

```swift
struct CardsDependencies {
    var repository: CardsRepositoryProtocol
    var featureFlags: FeatureFlagProviding
    var session: SessionProviding
    var logger: Loggable

    init(external: CardsExternalDependencies) {
        self.repository = CardsRepository()
        self.featureFlags = external.featureFlags
        self.session = external.session
        self.logger = ClaraLog(category: "Cards",
                               bugReporter: external.bugReporter)
    }
}
```

### 3. `AppContainer` owns shared instances and conforms via extensions

`AppContainer` is created once in `AppDelegate`. It conforms to each module's external dependencies protocol through extensions — one extension per module.

```swift
// Core/DI/AppContainer.swift

final class AppContainer {
    let session: SessionProviding
    let featureFlags: FeatureFlagProviding
    let bugReporter: BugReportLoggable

    init(
        session: SessionProviding = AppSession(),
        featureFlags: FeatureFlagProviding = LaunchDarklyFlagManager(),
        bugReporter: BugReportLoggable = LuciqBugReporter()
    ) {
        self.session = session
        self.featureFlags = featureFlags
        self.bugReporter = bugReporter
    }
}

// One extension per module — conformance via composition
extension AppContainer: CardsExternalDependencies {}
extension AppContainer: TransactionsExternalDependencies {}
extension AppContainer: ReimbursementsExternalDependencies {}
extension AppContainer: AuthExternalDependencies {}
```

### 4. Coordinators receive the protocol — not the container

Coordinators are passed the container as the module's protocol type. The module never imports or knows about `AppContainer`.

```swift
final class CardsCoordinator {
    private let externalDependencies: CardsExternalDependencies

    init(externalDependencies: CardsExternalDependencies) {
        self.externalDependencies = externalDependencies
    }

    func showCardList() {
        let deps = CardsDependencies(external: externalDependencies)
        let viewModel = CardsViewModel(dependencies: deps)
        ...
    }
}

// AppCoordinator wires coordinators passing the container as the protocol
CardsCoordinator(externalDependencies: container)
```

### 5. ViewModels receive the Dependencies struct

ViewModels never access the container or the external protocol directly. They receive the fully built `Dependencies` struct.

```swift
final class CardsViewModel: ObservableObject {
    private let dependencies: CardsDependencies

    init(dependencies: CardsDependencies) {
        self.dependencies = dependencies
    }

    func loadCards() async {
        dependencies.logger.info("Loading cards")
        do {
            let cards = try await dependencies.repository.fetchCards()
            ...
        } catch {
            dependencies.logger.error("Failed: \(error)")
        }
    }
}
```

---

## Dependency Flow

```
AppDelegate
    └── AppContainer (created once)
            ├── session: SessionProviding         ← shared
            ├── featureFlags: FeatureFlagProviding ← shared
            └── bugReporter: BugReportLoggable    ← shared
                    │
                    │ passed as protocol type
                    ▼
            Coordinator
                    │
                    │ builds module dependencies
                    ▼
            ModuleDependencies(external:)
                    │
                    ▼
            ViewModel / UseCase
```

---

## Testing

Tests never need to build `AppContainer`. A simple mock struct conforming to the module protocol is enough.

```swift
// Lightweight mock — only what the module needs
struct MockCardsExternalDependencies: CardsExternalDependencies {
    var session: SessionProviding = MockSession()
    var featureFlags: FeatureFlagProviding = MockFeatureFlagManager()
    var bugReporter: BugReportLoggable = MockBugReporter()
}

// Override individual dependencies per test
func test_loadCards_logsErrorOnFailure() async {
    var deps = CardsDependencies(external: MockCardsExternalDependencies())
    deps.repository = MockCardsRepository(shouldFail: true)

    let viewModel = CardsViewModel(dependencies: deps)
    await viewModel.loadCards()

    XCTAssertFalse(mockLogger.errorMessages.isEmpty)
}
```

---

## Rules

1. **Every dependency is a protocol** — `Dependencies` structs never hold concrete types
2. **Modules never import `AppContainer`** — they only know their own `ExternalDependencies` protocol
3. **`AppContainer` is the only place** concrete types are instantiated
4. **Shared instances** (session, feature flags, bug reporter) live in `AppContainer` and are passed down
5. **Module-scoped instances** (repositories, loggers) are created inside `ModuleDependencies.init(external:)`
6. **No `.shared` access anywhere** — if a class calls `.shared`, it has a hidden dependency
7. **Coordinators pass the container as the protocol type** — never as `AppContainer`

---

## Adding a New Module

1. Define `ModuleExternalDependencies` protocol in the module
2. Create `ModuleDependencies` struct with `init(external:)`
3. Add `extension AppContainer: ModuleExternalDependencies {}` in `Core/DI/`
4. Create coordinator with `externalDependencies: ModuleExternalDependencies`
5. Create `MockModuleExternalDependencies` for tests

---

## Migration

Existing code migrates gradually. New modules follow this pattern from day one. When touching an existing class, replace `.shared` access with an injected dependency. Do not do bulk migrations.
