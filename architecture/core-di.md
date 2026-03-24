# Core/DI — Dependency Injection

## The Problem

Right now there are three different ways dependencies get created in the same codebase. No single approach won.

**Pattern 1 — Init injection with default values**

Some coordinators take their dependencies through `init`, which is the right idea. But it got out of hand. `AppCoordinator` takes 8 parameters. `CardsFactory` takes 13. Nobody wants to touch those inits. New features get added by tacking on another default parameter and hoping nothing breaks.

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

Even in classes that do use init injection, the body often reaches for globals anyway. The init signature lies — it says a class needs 3 things, but reading the implementation reveals 5 more hidden dependencies.

```swift
// Hidden dependencies — not visible in init, not swappable in tests
Session.shared.user
RemoteConfigurationManager.shared.isAddToWalletFeatureAvailable
SnackbarManager.shared.show(...)
ZendeskManager.shared.showChatView(...)
```

**Pattern 3 — No injection at all**

Some classes just create their own dependencies inline. No protocol, no override, no way in for a test.

```swift
let repository = CardsRepository()  // created inside the class, not injectable
```

---

## Why This Makes Testing Hard

To unit test a ViewModel today you need a real `Session.shared` with valid state, LaunchDarkly initialized and returning the right flags, and repositories that make real network calls. None of those are controllable in a test.

That's why most of the app has no unit tests — not because nobody wanted to write them, but because the architecture makes it nearly impossible.

```swift
// Cannot test this today — Session.shared and RemoteConfigurationManager.shared
// are not swappable, so every test hits real state
func test_addToWallet_hiddenWhenFlagDisabled() {
    // How do you set RemoteConfigurationManager.shared to return false?
    // You can't — it's a singleton tied to LaunchDarkly
}
```

---

## Why Consistency Matters

Three patterns living side by side means every developer makes a different judgment call. New code copies the nearest example — sometimes init injection, sometimes `.shared`, sometimes inline. Over time nobody can look at a class and know what it actually depends on without reading every line.

The goal is one pattern that any engineer can follow without having to think about it.

---

## The Design

### `DependencyValues` — one struct, everything in one place

All dependencies live in a single struct. This is the only place you need to look to understand what the app depends on.

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

### `Dependencies` — the single global entry point

Set once at app startup. A struct, not a class — which means the whole thing is replaceable in tests.

```swift
// Core/DI/Dependencies.swift

enum Dependencies {
    nonisolated(unsafe) static var current = DependencyValues()
}
```

### `@Inject` — resolves via KeyPath, fully type-safe

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

### Usage — dependencies declared at the top of every class

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

SDKs must be started before `DependencyValues` is configured. The defaults in `DependencyValues` are lightweight wrappers — they assume the SDK is already running, they don't start it.

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

Replace `Dependencies.current` in `setUp()`, reset it in `tearDown()`. Override only what the test needs — everything else uses the real default from `DependencyValues`.

```swift
final class CardsViewModelTests: XCTestCase {

    override func tearDown() {
        // Always reset — prevents state leaking between tests
        Dependencies.current = DependencyValues()
    }

    func test_loadCards_returnsCards() async {
        var deps = DependencyValues()
        deps.cardsRepository = MockCardsRepository(cardList: .stub())
        Dependencies.current = deps

        let viewModel = CardsViewModel()
        await viewModel.loadCards()

        XCTAssertFalse(viewModel.cards.isEmpty)
    }

    func test_loadCards_onFailure_showsError() async {
        var deps = DependencyValues()
        deps.cardsRepository = MockCardsRepository(shouldFail: true)
        Dependencies.current = deps

        let viewModel = CardsViewModel()
        await viewModel.loadCards()

        XCTAssertTrue(viewModel.hasError)
    }

    func test_addToWallet_hiddenWhenFlagDisabled() {
        var deps = DependencyValues()
        deps.featureFlags = MockFeatureFlagManager(addToWallet: false)
        Dependencies.current = deps

        let viewModel = CardsViewModel()

        XCTAssertFalse(viewModel.isAddToWalletVisible)
    }

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
}

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
3. Add a mock implementation in the test target

The compiler enforces that the KeyPath exists — no runtime surprises.

---

## Performance

Allocating `DependencyValues` creates lightweight wrapper objects — microseconds total. It does not affect launch time. The expensive work (SDK initialization) already happened in `AppDelegate` before `DependencyValues` is created.

---

## Known Limitations

### 1. Global mutable state
`Dependencies.current` is a global. Tests that forget `tearDown()` corrupt state for every test that runs after them. The reset is a convention, not something the compiler enforces. If you ever run tests in parallel, this will bite you.

### 2. No compile-time enforcement of `tearDown`
The compiler can't tell you a test forgot to reset `Dependencies.current`. The failure shows up somewhere else — a different test behaving unexpectedly, hard to trace back to the original culprit.

### 3. `@Inject` resolves at access, not at init
A property wrapper reads `Dependencies.current` the first time it's accessed, not when the class is created. That means you can't override a dependency after an instance has already used it. If you instantiate a class and then swap `Dependencies.current`, the already-running instance won't see the change.

### 4. `DependencyValues` grows with the codebase
Every new repository, logger, and service adds another property. There's no way to group or scope them. As the team grows, this struct gets harder to navigate and every instantiation allocates the full set of defaults even when only a couple are needed.

### 5. No session-scoped dependencies
Everything in `DependencyValues` is effectively a singleton for the lifetime of `Dependencies.current`. There's no built-in concept of a dependency that should reset between user sessions — for example, clearing cached state after logout. That kind of lifecycle management has to be handled manually, outside the container.
