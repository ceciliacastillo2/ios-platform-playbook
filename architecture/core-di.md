# Core/DI — Dependency Injection

## Goal

Replace all `.shared` singleton access with explicit, protocol-based dependencies. Every class declares what it needs via `@Inject` — visible at the top of the class, enforced by the compiler, swappable in tests.

No DI framework. No multiple init parameters. One place to see all dependencies.

---

## Design

### 1. `DependencyValues` — one struct, everything visible

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
    var reimbursementsRepository: ReimbursementsRepositoryProtocol = AppReimbursementsRepository()
    var credentialsRepository: CredentialsRepositoryProtocol = CredentialsRepository()
    var userRepository: UserRepositoryProtocol = UserRepository()

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
    RemoteConfigurationManager.start()

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
        deps.cardsRepository = MockCardsRepository(cards: [.stub()])
        Dependencies.current = deps

        let viewModel = CardsViewModel()
        await viewModel.loadCards()

        XCTAssertEqual(viewModel.cards.count, 1)
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
    private let cards: [Card]
    private let shouldFail: Bool

    init(cards: [Card] = [], shouldFail: Bool = false) {
        self.cards = cards
        self.shouldFail = shouldFail
    }

    func fetchCards() async throws -> [Card] {
        if shouldFail { throw CardsError.networkingUnknown }
        return cards
    }
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
