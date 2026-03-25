# Core/DI — Dependency Injection

## Goal

Converge on a single dependency injection pattern. The specific mechanism is still being evaluated, but the outcome is fixed: dependencies are injected, not grabbed from globals or constructed inline.

**What success looks like**

- Any class's dependencies are visible at a glance — no hidden `.shared` access, no inline construction.
- Writing a unit test for a ViewModel takes minutes, not hours. You override only what the test needs; the rest uses real defaults.
- New engineers follow one pattern because there is only one pattern. The nearest example in the codebase is always the right example.
- `CardsFactory` and `AppCoordinator` no longer have double-digit init parameters. Dependency count is visible and stays honest.
- CI fails if a new `.shared` reference is introduced — the rules are enforced, not just documented.

---

## The Problem

Right now there are three different ways dependencies get created in the same codebase. No single approach won.

**Pattern 1  Init injection with default values**

Some coordinators take their dependencies through `init`, which is the right idea. But it got out of hand. `AppCoordinator` takes 8 parameters. `CardsFactory` takes 13. Nobody wants to touch those inits. New features get added by tacking on another default parameter and hoping nothing breaks.

```swift
// CardsFactory today  13 parameters, grows with every feature
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

**Pattern 2 Direct singleton access**

Even in classes that do use init injection, the body often reaches for globals anyway. The init signature lies it says a class needs 3 things, but reading the implementation reveals 5 more hidden dependencies.

```swift
// Hidden dependencies  not visible in init, not swappable in tests
Session.shared.user
RemoteConfigurationManager.shared.isAddToWalletFeatureAvailable
SnackbarManager.shared.show(...)
ZendeskManager.shared.showChatView(...)
```

**Pattern 3 No injection at all**

Some classes just create their own dependencies inline. No protocol, no override, no way in for a test.

```swift
let repository = CardsRepository()  // created inside the class, not injectable
```

---

## Why This Makes Testing Hard

To unit test a ViewModel today you need a real `Session.shared` with valid state, LaunchDarkly initialized and returning the right flags, and repositories that make real network calls. None of those are controllable in a test.

That's why most of the app has no unit tests not because nobody wanted to write them, but because the architecture makes it challenging.

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


### Goal dependencies declared at the top of every class

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

## Testing

Replace `Dependencies.current` in `setUp()`, reset it in `tearDown()`. Override only what the test needs — everything else uses the real default from `DependencyValues`.

```swift

```

### Mock examples

```swift

```

---

## Rules

1. **Every dependency is a protocol** 
2. **No `.shared` access anywhere** use `@Inject` instead
3. **`@Inject` is declared at the top of the class**  never resolved mid-method
4. **Defaults must be lightweight**  no network calls, file I/O, or SDK initialization in default values
5. **SDKs are started in `AppDelegate`** before `DependencyContainer` is configured
6. **Tests always reset** in `tearDown()`

---

## Adding a New Dependency

1. Add the protocol property to `TODO` with a default value
2. Use `@Inject(\.newDependency)` in the class that needs it
3. Add a mock implementation in the test target

The compiler enforces that the KeyPath exists no runtime surprises.
