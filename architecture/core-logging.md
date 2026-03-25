# Core/Logging

---

## Current State

Logging is inconsistent across the codebase. Over 102 files use `print()` or `debugPrint()` directly with no log levels, no categorisation, and no privacy controls. `LuciqSDK` is imported directly in feature files to call `LCQLog` — leaking a third-party dependency across the codebase.

---

## Goal

Introduce a protocol-based logging system in `Core/Logging/` that is injectable, testable, and isolates all third-party dependencies behind protocols. Feature modules depend only on `Loggable`  they have no knowledge of `os.Logger`, `LuciqSDK`, or any other destination.

Replacing the bug reporting provider requires changing one file. No feature code changes.

**What success looks like**

- No feature file contains `print()`, `debugPrint()`, or a direct `LCQLog` call.
- No feature module imports `LuciqSDK` — the SDK is used only in `LuciqBugReporter.swift`.
- Swapping the bug reporting provider is a one-file change with no feature code touched.
- A unit test can verify logging behaviour by injecting `MockLogger` — no SDK or console output required.
- Logs in Console.app are filterable by module category, making it fast to isolate issues during debugging.

---

## Structure

```
Core/Logging/
├── Loggable.swift              ← logging contract
├── BugReportLoggable.swift     ← bug reporting contract
├── ClaraLog.swift              ← real implementation
└── LuciqBugReporter.swift      ← only file that imports LuciqSDK

// Test target only
└── MockLogger.swift            ← test implementation, never in production code
```

---

## Example

```swift
// Feature code — depends only on Loggable, no SDK imports
final class CardsRepository: CardsRepositoryProtocol {
    private let logger: Loggable

    init(logger: Loggable = ClaraLog(category: "Cards")) {
        self.logger = logger
    }

    func fetchCards() async throws -> CardList {
        logger.info("Fetching cards")
        do {
            ...
        } catch {
            logger.error("Failed to fetch cards: \(error)")
            throw error
        }
    }
}
```

---

## Log Levels

| Level | Forwarded to Luciq | When to use |
|---|---|---|
| `debug` | No | Development noise stripped in Release |
| `info` | Yes | Notable events request completed, user logged in |
| `error` | Yes | Failures worth investigating |
| `fault` | Yes | Critical unrecoverable failures |

---

## Privacy Rules

| Data | Rule |
|---|---|
| Tokens, credentials, passwords | Never log |
| User IDs, personal data | Debug only |
| URLs, status codes, flow names | Safe at any level |
| Request bodies | Never log in production |

---

## Migration Rule

Do not do a bulk migration pass. Replace `print()`, `debugPrint()`, and direct `LCQLog` calls when a file is already being touched. All new files must use `Loggable`.

---

## Module Categories

Each module owns its category string. This makes logs filterable by domain in Console.app.

| Module | Category |
|---|---|
| `Core/Networking` | `"Networking"` |
| `Core/WebSocket` | `"WebSocket"` |
| `Core/Session` | `"Session"` |
| `Core/FeatureFlags` | `"FeatureFlags"` |
| `Core/PushNotifications` | `"PushNotifications"` |
| `Cards` | `"Cards"` |
| `Transactions` | `"Transactions"` |
| `Reimbursements` | `"Reimbursements"` |
| `Auth` | `"Auth"` |
| `Profile` | `"Profile"` |
| `Collections` | `"Collections"` |
| `Tasks` | `"Tasks"` |
