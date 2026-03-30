# Core/Networking — ClaraNetworking

---

## Overview

Backend communication is handled through an internal Swift package called `ClaraNetworking`. It provides all the infrastructure for making HTTP requests and WebSocket connections. Feature modules never interact with `URLSession` directly — all networking goes through this package.

---

## Protocols

The backend is accessed via two protocols:

**REST — `Router`**
Defines everything needed to construct an HTTP request: scheme, host, path, method, headers, body, and query parameters. Each domain defines its endpoints as an enum conforming to `Router`.

**Real-time — `WebSocketRouter`**
Defines everything needed to open a WebSocket connection using STOMP framing: host, path, destination topic, auth token, and headers. Used for real-time data streams.

---

## Components

| File | Responsibility |
|---|---|
| `Router` | Protocol — defines an HTTP endpoint |
| `WebSocketRouter` | Protocol — defines a WebSocket endpoint |
| `RequestPerformer` | Executes REST requests via `URLSession` |
| `WebSocketPerformer` | Manages WebSocket connections with STOMP framing |
| `ExpectedResponseType` | Tells the performer how to handle the response — decode an object or expect a successful status |
| `ClaraNetworkingError` | Maps HTTP status codes and `URLError` to typed domain errors |
| `HTTPStatusCode` | Maps raw status codes to typed cases |
| `BackgroundService` | Handles background multipart file uploads |

---

## Request Flow

```
Feature Code
└── Repository (protocol)
        └── Repository (base class)
                └── RequestPerformer
                            └── URLSession
                                    └── Clara API
```

1. Feature code calls a method on a `Repository` protocol
2. The concrete repository builds a `Router` for the specific endpoint
3. Passes it to `RequestPerformer` which executes the `URLSession` call
4. Response is decoded into a typed model and returned via `async/await`
5. Networking errors are mapped to `ClaraNetworkingError`

---

## WebSocket Flow

```
Feature Code
└── Repository
        └── WebSocketRepository (base)
                └── WebSocketPerformer
                            └── URLSessionWebSocketTask
                                    └── STOMP handshake
                                            └── Topic subscription
                                                    └── AsyncThrowingStream<T>
```

Real-time data is consumed as an `AsyncThrowingStream` — feature code iterates over events as they arrive:

```swift
for try await update in repository.subscribeToCardUpdates() {
    handle(update)
}
```

---

## Authentication

All requests are authenticated automatically. A `Router` extension injects the bearer token from the current session into every request feature code never handles auth headers manually.

---

## Current Status — Endpoint Inventory

Grouped by domain. Statuses reflect what is registered in Router files as of March 2026.

### Authentication & Session

| Endpoint | Status |
|---|---|
| `/credentials/auth0/login/mobile` | Active |
| `/credentials/logout` | Active |
| `/credentials/refresh` | Active |
| `/credentials/refreshScopedJWT` | Active |
| `/credentials/switchCompany/mobile` | Active |
| `/credentials/addScopes` | Active |
| `/credentials/encryptionKeys` | Active |
| `/otp/generateCode` | Active |

### Cards

| Endpoint | Status |
|---|---|
| `/mobile/cards/v2` | Active |
| `/mobile/cards/v2/{cardId}` | Active |
| `/mobile/cards/{cardUUID}` | Active |
| `/mobile/cards/activate` | Active |
| `/mobile/cards/lock` | Active |
| `/mobile/cards/limits` | Active |
| `/mobile/cards/sec-code` | Active |
| `/mobile/cards/pin/{cardUUID}` | Active |
| `/mobile/cards/{cardId}/nip` | Active |
| `/mobile/cards/nip/{cardId}` | Active |
| `/mobile/cards/{cardId}/registration` | Active |
| `/cards/v2/{cardUUID}` | Active |
| `/cards/v2/card-balance/{cardId}` | Active |
| `/cards/v2/getCards-notBalance` | Deprecated — uses `CardListParametersDeprecated` |
| `/cards/actions` | Deprecated — case `pinDeprecated`, uses `RequestPINParametersDeprecated` |
| `/cards/request` | Active |
| `/cards/requestThreshold` | Active |
| `/card_delivering` | Unknown — not found in any Router file |

### Transactions

| Endpoint | Status |
|---|---|
| `/transactions` | Active |
| `/transactions/{transactionID}` | Active |
| `/transactions/{transactionID}/comment` | Active |
| `/transactions/{transactionID}/suggestion/v2` | Active |
| `/transactions/{transactionId}/fallback-suggestions` | Active |
| `/transactions/{transactionId}/{invoiceId}/assignCDFI-v2` | Active |
| `/transactions/approval/v2/request/{transactionID}` | Active |
| `/mobile/{cardId}/transaction` | Active |

### Documents & OCR

| Endpoint | Status |
|---|---|
| `/documents/{documentID}` | Active |
| `/documents/{documentID}/xmlData` | Active |
| `/documents/company/downloadUrl` | Active |
| `/documents/transaction/downloadUrl` | Active |
| `/documents/transaction/{transactionID}/{documentID}` | Active |
| `/documents/transaction/{transactionID}/signedUrl/v2` | Active |
| `/documents/transaction/upload-segment-event/{transactionId}` | Active |
| `/transactions-docs/{transactionID}` | Active |
| `/transactions-docs/async/{transactionId}` | Active |
| `/transactions-docs-ocr/{fileUuid}/extract` | Active |
| `/transactions-docs-validate` | Active |

### Reimbursements

| Endpoint | Status |
|---|---|
| `/reimbursements/` | Active |
| `/reimbursements/{id}/` | Active |
| `/reimbursements/attachment` | Active |
| `/reimbursements/attachment/{id}` | Active |
| `/reimbursements/bank` | Active |
| `/reimbursements/merchant` | Active |
| `/reimbursements/user-bank` | Active |
| `/reimbursements/v1/user-bank` | Possibly newer version |
| `/reimbursements-events` | Active (WebSocket) |
| `/user/queue/reimbursements-events` | Active (WebSocket) |

### Expenses

| Endpoint | Status |
|---|---|
| `/expenses` | Active |
| `/expenses/{id}` | Active |
| `/expenses/bulk` | Active |
| `/expenses/search/general` | Active |
| `/expenses/drafts` | Active |
| `/expenses/{draftId}/drafts/submit` | Active |
| `/expenses/{id}/attachments` | Active |

### User & Company

| Endpoint | Status |
|---|---|
| `/user` | Active |
| `/user/{userID}` | Active |
| `/user/v2` | Active |
| `/user/v2/changeMobilePhone` | Active |
| `/user/countryPhoneCodes` | Active |
| `/user-creation/mobile/updateInfo` | Active |
| `/company` | Active |
| `/company/billingInfo` | Active |
| `/company/companies` | Active |

### Labels

| Endpoint | Status |
|---|---|
| `/labels/v1` | Active |

### Collections & Billing

| Endpoint | Status |
|---|---|
| `/collections/billing-statements` | Active |
| `/collections/full-account` | Active |
| `/collections/validate` | Active |
| `/insights/billingCycle` | Active |

### Approvals

| Endpoint | Status |
|---|---|
| `/approvals-manager/approval-flows/company-settings/{companyId}` | Active |

### Claims

| Endpoint | Status |
|---|---|
| `/claims/transaction` | Active |
| `/claims/reasons` | Active |
| `/claims/status` | Active |

### External / Integrations

| Endpoint | Status |
|---|---|
| `/zendesk-integration-services/zendesk-widgets-sdk/end-user/jwt` | Active |
| `/referral-jwt` | Active |
| `/tokenization/accessToken/k08/{consumerId}` | Active |
| `/kublau` | Active (card tracking) |
| `/satws/getStatus` | Active |
| `/documentation/{language}` | Active |

### Open Questions

- **`/card_delivering`** — does not appear in any Router file. May be a dead route, dynamically constructed, or defined outside the standard Router pattern. Run `grep -r "card_delivering" <project-root>` to confirm.

---
