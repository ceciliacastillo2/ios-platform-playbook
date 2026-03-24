# Core/DI — Dependency Injection

## The Problem

Dependency injection is currently done three different ways in the same codebase, with no consistency across modules.

**Pattern 1 — Init injection with default values**

Some coordinators and factories declare dependencies in `init` with concrete defaults. `AppCoordinator` takes 8 parameters. `CardsFactory` takes 13. This approach is structurally correct but breaks down as the team grows — every new feature adds more parameters, and the init signature becomes a maintenance burden nobody wants to touch.

```swift
// CardsFactory today — 13 parameters, grows with every feature
init(user: User,
     country: Country,
     labelsUseCase: LabelsUseCaseProtocol,
     hasApprovalFlowAccess: Bool,
     cardsRepositoryDeprecated: CardsRepositoryType = CardsRepositoryDeprecated(),
     cardsLoadingRepository: CardsLoadingRepositoryProtocol = CardsRepository(),
     cardsRepository: CardsRepositoryProtocol = CardsRepository(),
     transactionsRepository: TransactionsRepositoryProtocol = TransactionsRepository(),
     oldTransactionsRepository: TransactionsRepositoryType = TransactionsRepositoryOld(),
     claimsRepository: ClaimsRepositoryType = ClaimsRepository(),
     companyRepository: CompanyRepositoryType = CompanyRepository(),
     documentsRepository: DocumentsRepositoryDeprecated = DocumentsRepositoryDeprecated(),
     credentialsRepository: CredentialsRepositoryType = CredentialsRepository())
```

**Pattern 2 — Direct singleton access**

Despite having init injection in some places, most classes bypass it entirely and reach for globals directly. The init signature lies — it says a class needs 3 things but the body secretly uses 5 more.

```swift
// Hidden dependencies — not visible in init, not swappable in tests
Session.shared.user
RemoteConfigurationManager.shared.isAddToWalletFeatureAvailable
SnackbarManager.shared.show(...)
ZendeskManager.shared.showChatView(...)
```

**Pattern 3 — No injection at all**

Some classes instantiate their own dependencies inline with no way to override them.

```swift
let repository = CardsRepository()  // created inside the class, not injectable
```

---

## Why This Matters for Testing

With the current approach, writing a unit test for a ViewModel requires:

1. Building real repositories that make real network calls
2. Having a valid `Session.shared` state
3. Having LaunchDarkly initialized and returning the right flags

None of these are controllable in a test. The result is that most of the app has no unit tests — not because the team doesn't want to write them, but because the architecture makes it nearly impossible.

```swift
// Cannot test this today — Session.shared and RemoteConfigurationManager.shared
// are not swappable, so every test hits real state
func test_addToWallet_hiddenWhenFlagDisabled() {
    // How do you set RemoteConfigurationManager.shared to return false?
    // You can't — it's a singleton tied to LaunchDarkly
}
```

---

## Why Consistency Matters for a Growing Team

When three patterns coexist, every developer makes a different choice. New code copies the nearest example — sometimes init injection, sometimes `.shared`, sometimes inline instantiation. Over time the codebase becomes impossible to reason about. A new team member cannot look at a class and understand what it depends on without reading every line.

The goal is one pattern, everywhere, that any developer can follow without making a judgment call.

---

## Goal

Replace all `.shared` singleton access with explicit, protocol-based dependencies. Every class declares what it needs via `@Inject` — visible at the top of the class, enforced by the compiler, swappable in tests.

No DI framework. No multiple init parameters. One place to see all dependencies.

---

## Architect's Note

This approach trades one form of global state (`.shared` singletons) for another (`Dependencies.current`). That is an honest trade-off, not a perfect solution. The difference is that `Dependencies.current` is a value type — fully replaceable in tests with one line, with no side effects. Classic singletons are reference types with internal state that cannot be reset between tests.

`@Inject` also makes the trade-off visible. When you see `@Inject` at the top of a class you know the class depends on a global container. With `.shared` that dependency is hidden inside method bodies and impossible to find without reading every line.

For a team that will grow, the most important property of a DI system is not theoretical purity — it is that every developer follows the same pattern without thinking about it. `@Inject` with `DependencyValues` achieves that with minimal infrastructure.

The limitation to be aware of: parallel tests that mutate `Dependencies.current` can interfere with each other. Mitigate by always resetting in `tearDown()` and avoiding shared mutable state in mock implementations.

---

## Design

### 1. `DependencyValues`  one struct, everything visible

All dependencies are defined in a single struct. This is the only place you need to look to understand what the app depends on.

```swift
// Core/DI/DependencyValues.swift

struct DependencyValues {

    // Shared — one instance used across all modules
    var session: SessionProviding = AppSession()
    var featureFlags: FeatureFlagProviding = LaunchDarklyFlagManager()
    var bugReporter: BugReportLoggable = LuciqBugReporter()

    // Repositories — one per domain
    var cardsRepository: CardsRepositoryProtocol = CardsRepository()
    var transactionsRepository: TransactionsRepositoryProtocol = TransactionsRepository()
    var reimbursementsRepository: ReimbursementsRepository = AppReimbursementsRepository()
    var credentialsRepository: CredentialsRepositoryType = CredentialsRepository()
    var userRepository: UserRepositoryType = UserRepository()

    // Loggers — one per module
    var cardsLogger: Loggable = ClaraLog(category: "Cards")
    var transactionsLogger: Loggable = ClaraLog(category: "Transactions")
    var reimbursementsLogger: Loggable = ClaraLog(category: "Reimbursements")
    var authLogger: Loggable = ClaraLog(category: "Auth")
}
```

### 2. `Dependencies` — the single global entry point

Set once at app startup. A struct, not a class — fully replaceable in tests.

```swift
// Core/DI/Dependencies.swift

enum Dependencies {
    nonisolated(unsafe) static var current = DependencyValues()
}
```

### 3. `@Inject` — resolves via KeyPath, fully type-safe

```swift
// Core/DI/Inject.swift

@propertyWrapper
struct Inject<T> {
    private let keyPath: KeyPath<DependencyValues, T>

    var wrappedValue: T {
        Dependencies.current[keyPath: keyPath]
    }

    init(_ keyPath: KeyPath<DependencyValues, T>) {
        self.keyPath = keyPath
    }
}
```

### 4. Usage — dependencies declared at the top of every class

```swift
final class CardsViewModel: ObservableObject {
    @Inject(\.session) private var session
    @Inject(\.featureFlags) private var featureFlags
    @Inject(\.cardsRepository) private var repository
    @Inject(\.cardsLogger) private var logger

    func loadCards() async {
        logger.info("Loading cards")
        do {
            let cards = try await repository.fetchCards()
        } catch {
            logger.error("Failed to load cards: \(error)")
        }
    }
}
```

---

## App Startup

SDKs must be started before `DependencyValues` is configured. Defaults are lightweight wrappers — never the SDK initialization itself.

```swift
// AppDelegate.swift

func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions...) -> Bool {

    // 1. Start SDKs first — expensive work happens here
    LuciqManager.start()
    SiftManager.start()
    CustomerIOManager.start()
    LokaliseManager.start()
    _ = RemoteConfigurationManager.shared  // triggers initialization

    // 2. DependencyValues wraps already-running SDKs — cheap
    Dependencies.current = DependencyValues()

    return true
}
```

---

## Dependency Flow

```
AppDelegate
    └── SDKs started explicitly
    └── Dependencies.current = DependencyValues()
                │
                │ @Inject resolves at property access
                ▼
        ViewModel / UseCase
        @Inject(\.session)
        @Inject(\.cardsRepository)
        @Inject(\.cardsLogger)
```

---

## Testing

Replace `Dependencies.current` in `setUp()`. Reset in `tearDown()`. Override only what the test needs — everything else uses the default from `DependencyValues`.

```swift
final class CardsViewModelTests: XCTestCase {

    override func tearDown() {
        // Always reset after each test — prevents state leaking between tests
        Dependencies.current = DependencyValues()
    }

    // Test happy path — override only the repository
    func test_loadCards_returnsCards() async {
        var deps = DependencyValues()
        deps.cardsRepository = MockCardsRepository(cardList: .stub())
        Dependencies.current = deps

        let viewModel = CardsViewModel()
        await viewModel.loadCards()

        XCTAssertFalse(viewModel.cards.isEmpty)
    }

    // Test error path — repository fails, verify error state
    func test_loadCards_onFailure_showsError() async {
        var deps = DependencyValues()
        deps.cardsRepository = MockCardsRepository(shouldFail: true)
        Dependencies.current = deps

        let viewModel = CardsViewModel()
        await viewModel.loadCards()

        XCTAssertTrue(viewModel.hasError)
    }

    // Test feature flag — verify flag controls behaviour
    func test_addToWallet_hiddenWhenFlagDisabled() {
        var deps = DependencyValues()
        deps.featureFlags = MockFeatureFlagManager(addToWallet: false)
        Dependencies.current = deps

        let viewModel = CardsViewModel()

        XCTAssertFalse(viewModel.isAddToWalletVisible)
    }

    // Test logging — verify errors are logged
    func test_loadCards_onFailure_logsError() async {
        let mockLogger = MockLogger()
        var deps = DependencyValues()
        deps.cardsRepository = MockCardsRepository(shouldFail: true)
        deps.cardsLogger = mockLogger
        Dependencies.current = deps

        let viewModel = CardsViewModel()
        await viewModel.loadCards()

        XCTAssertTrue(mockLogger.errorMessages.contains { $0.contains("Failed to load cards") })
    }
}
```

### Mock examples

```swift
// MockCardsRepository.swift
final class MockCardsRepository: CardsRepositoryProtocol {
    private let cardList: CardList
    private let shouldFail: Bool

    init(cardList: CardList = .stub(), shouldFail: Bool = false) {
        self.cardList = cardList
        self.shouldFail = shouldFail
    }

    func fetchCards(with parameters: CardListParameters) async throws(CardsError) -> CardList {
        if shouldFail { throw .networkingUnknown }
        return cardList
    }

    // Remaining protocol stubs omitted for brevity
}

// MockFeatureFlagManager.swift
final class MockFeatureFlagManager: FeatureFlagProviding {
    var addToWallet: Bool

    init(addToWallet: Bool = false) {
        self.addToWallet = addToWallet
    }

    var isAddToWalletFeatureAvailable: Bool { addToWallet }
}
```

---

## Rules

1. **Every dependency is a protocol** — `DependencyValues` never holds a concrete type
2. **No `.shared` access anywhere** — use `@Inject` instead
3. **`@Inject` is declared at the top of the class** — never resolved mid-method
4. **Defaults must be lightweight** — no network calls, file I/O, or SDK initialization in default values
5. **SDKs are started in `AppDelegate`** before `DependencyValues` is configured
6. **Tests always reset** `Dependencies.current = DependencyValues()` in `tearDown()`

---

## Adding a New Dependency

1. Add the protocol property to `DependencyValues` with a default value
2. Use `@Inject(\.newDependency)` in the class that needs it
3. Add a mock implementation for tests

The compiler enforces that the KeyPath exists — no runtime surprises.

---

## Performance

Creating `DependencyValues` allocates lightweight wrapper objects — microseconds per object. This does not affect app launch time. The expensive work (SDK initialization) happens explicitly in `AppDelegate` before `DependencyValues` is created.

---

## Migration

Never do a bulk migration. Replace `.shared` access when a file is already being touched for another reason. New files must use `@Inject` from day one.
