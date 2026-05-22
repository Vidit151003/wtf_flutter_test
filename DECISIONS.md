# Architecture Decision Records — WTF Flutter Test

This file documents the key architectural decisions made during development, including context, options considered, the decision taken, and its consequences.

---

## ADR #1 — State Management: Provider + ChangeNotifier

**Date**: 2026-05-22  
**Status**: Accepted

### Context

The app needs a state management solution to coordinate:
- Auth state (logged-in user, role)
- Chat messages (real-time-like updates, optimistic writes)
- Schedule slots (selection, booking)
- Call state (joining, mic/camera toggles, reconnect)

Options considered:

| Option      | Pros                                        | Cons                                             |
|-------------|---------------------------------------------|--------------------------------------------------|
| **Provider**    | Simple, Flutter team recommended, no code gen | More verbose for complex derived state           |
| **Riverpod**    | Compile-safe, testable, powerful AsyncValue  | More magic (annotations), steeper learning curve |
| **Bloc**        | Very explicit, event-driven, time-travel debug | High boilerplate (Events + States + Bloc class)  |
| **GetX**        | Minimal boilerplate, built-in routing        | Global state is implicit, harder to test, non-idiomatic |

### Decision

**Provider + ChangeNotifier**

### Rationale

1. **Interview-readable**: ChangeNotifier is explicit — every state mutation calls `notifyListeners()`. Reviewers can follow the data flow without knowing Provider internals.
2. **No code generation**: Unlike Riverpod (with `@riverpod`) or Bloc (with `bloc_test`), Provider requires zero build tooling. `flutter pub get && flutter run` works immediately.
3. **Sufficient for this scale**: The app has ~4 providers per app. Provider's limitations (no compile-safe reads across providers, no `AsyncValue`) don't apply at this complexity level.
4. **Constructor injection**: Services are passed into Providers via constructor, keeping them testable without a service locator.
5. **Assessment alignment**: Provider is the most commonly expected answer in Flutter technical assessments.

### Consequences

- ✅ Less boilerplate than Bloc
- ✅ No magic or code generation
- ✅ Each `notifyListeners()` call is a visible, searchable commit to state change
- ⚠️ More verbose than Riverpod for derived/async state (e.g., `FutureProvider` equivalent requires manual `_isLoading` flags)
- ⚠️ `context.watch<T>()` requires a valid `BuildContext` in the widget tree — no reading outside widgets without a workaround

---

## ADR #2 — Storage: Hive (local) + Firestore (sync — pending)

**Date**: 2026-05-22  
**Status**: Accepted (Hive implemented; Firestore pending)

### Context

The app needs:
- **Fast local reads** — chat history, session logs, and user data must load without a network round-trip
- **Offline support** — core features (view history, compose message) must work without internet
- **Real-time sync** — trainer and member must see each other's messages and call requests without polling

Options considered:

| Option             | Pros                                          | Cons                                               |
|--------------------|-----------------------------------------------|----------------------------------------------------|
| **Hive + Firestore** | Fast binary local store + real-time streams  | Two systems to maintain; adapter registration      |
| **SQLite (drift)**  | Relational, type-safe queries                 | Overkill for document-shaped data; more setup      |
| **SharedPreferences** | Simple                                      | Not suitable for collections of objects            |
| **Firestore only**  | Single source of truth, real-time            | Requires network; no offline-first without extra config |
| **ObjectBox**       | Fastest local NoSQL                           | Paid for some features; heavier dependency         |

### Decision

**Hive** for local storage, **Firestore** as the sync layer (planned, not yet integrated).

### Rationale

1. **Hive performance**: Hive uses binary key-value storage with no reflection — reads are significantly faster than SQLite for simple document access patterns. It works in background isolates.
2. **Write-through cache pattern**: Every write goes to Hive first (synchronous), then to Firestore (async). The UI never waits for the network.
3. **Firestore real-time streams**: `snapshots()` provides real-time delivery of messages and call requests between the Trainer and Guru apps without building a custom WebSocket server.
4. **Swap-friendly service layer**: The abstract `ChatService` interface means the Hive mock can be replaced with a Firestore implementation by changing one `Provider<ChatService>` binding.
5. **Assessment scope**: Hive local storage is fully implemented and testable now; Firestore integration is a clearly scoped next step that doesn't block any current functionality.

### Consequences

- ✅ App works fully offline with seeded data
- ✅ No network required for development and demo
- ✅ Hive reads are synchronous — no `FutureBuilder` boilerplate for local data
- ⚠️ All Hive adapters must be registered before `Hive.openBox()` — order matters; `HiveConfig.init()` enforces this
- ⚠️ Firestore security rules must be authored before production; placeholder rules are permissive
- ⚠️ Hive does not support complex queries — filtering is done in Dart after loading the full box

---

## ADR #3 — Real-time Video/Audio: 100ms SDK

**Date**: 2026-05-22  
**Status**: Accepted (pending credential configuration)

### Context

The assessment requires production-quality real-time video/audio between the Trainer and Guru apps. Options considered:

| Option              | Pros                                              | Cons                                               |
|---------------------|---------------------------------------------------|----------------------------------------------------|
| **100ms (hmssdk_flutter)** | Assessment mandates it; role-based rooms; no billing on dev | Requires account setup; token server needed |
| **Agora**           | Mature SDK, large community                       | Not assessment-specified; billing starts earlier   |
| **WebRTC (raw)**    | Maximum control                                   | Requires custom signalling server; massive scope    |
| **Firebase + WebRTC** | Integrated with existing stack                  | Complex signalling; no production support          |
| **Jitsi Meet**      | Open source, free                                 | Flutter SDK less mature; limited role management   |

### Decision

**hmssdk_flutter** (100ms Flutter SDK)

### Rationale

1. **Assessment requirement**: The assessment explicitly mandates 100ms for RTC.
2. **Role-based room management**: 100ms templates define `trainer` and `member` roles with different permissions (e.g., trainer can end the room for all participants). This is built-in, not custom code.
3. **No billing on developer tier**: The 100ms developer project supports free usage with sufficient limits for an assessment and demo.
4. **Actively maintained Flutter SDK**: `hmssdk_flutter` is maintained by the 100ms team with regular updates and a Flutter-idiomatic API.
5. **Token server architecture**: The JWT token server (`token_server/`) keeps the `HMS_SECRET` off the device. This is the correct production pattern — never embed credentials in an app bundle.
6. **Stub-first development**: The `CallProvider` is designed to log a warning and skip SDK calls when credentials are not configured, allowing all other features to be developed and demonstrated without completing the 100ms setup.

### Consequences

- ✅ Production-quality RTC with no custom WebSocket/TURN server
- ✅ Role-based call control (trainer ends call for both participants)
- ✅ Session log is written to Hive on every call end, regardless of 100ms status
- ⚠️ Requires a 100ms account, a room template with `trainer` and `member` roles, and at least one room created
- ⚠️ The `token_server` must be reachable from the device running the Flutter app (use `ngrok` or LAN IP for physical devices)
- ⚠️ `HMS_ACCESS_KEY` and `HMS_SECRET` must never be committed to version control — enforced via `.gitignore` on `.env`
