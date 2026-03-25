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

## Improvements

| Issue | Goal |
|---|---|
| `RequestPerformer` has no protocol | Extract `RequestPerforming` to enable mocking in tests |
| No central serialisation | Introduce `NetworkCoder` for consistent encoding and decoding |
| Callback-based methods still exist | Migrate all remaining `@escaping` completions to `async/await` |
