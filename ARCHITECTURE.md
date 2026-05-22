# Architecture — WTF Flutter Test

This document describes the technical architecture of the WTF Flutter Test monorepo, covering data flow, service design, state management, and integration patterns.

---

## 1. Monorepo Structure Rationale

```
wtf_flutter_test/
├── shared/               # Dart package — shared across both apps
│   ├── lib/
│   │   ├── models/       # Hive data models (UserModel, MessageModel, …)
│   │   ├── services/     # Abstract service interfaces + mock implementations
│   │   ├── widgets/      # Reusable UI widgets (avatars, tiles, loaders)
│   │   └── utils/        # AppLogger, Validators, extensions
├── guru_app/             # Member-facing Flutter app
│   └── lib/
│       ├── providers/    # AuthProvider, ChatProvider, ScheduleProvider, CallProvider
│       ├── screens/      # HomeScreen, ConversationScreen, ScheduleScreen, CallScreen
│       └── main.dart
├── trainer_app/          # Trainer-facing Flutter app
│   └── lib/
│       ├── providers/    # AuthProvider, ChatProvider, SessionProvider, CallProvider
│       ├── screens/      # DashboardScreen, MemberDetailScreen, CallScreen
│       └── main.dart
└── token_server/         # Node.js — 100ms JWT token generator
```

**Why a shared package?**

Both apps operate on the same domain objects (`UserModel`, `MessageModel`, `CallRequestModel`, etc.) and share service interfaces. Extracting these into a `shared` Dart package:

- Eliminates code duplication between apps
- Enforces a single source of truth for models and service contracts
- Allows the mock implementation to be swapped for Firebase without touching app code
- Makes unit testing easier — tests live in `shared/test/` and cover both apps

---

## 2. Local-First Data Flow

```
User Action
    │
    ▼
ChangeNotifier Provider
    │           │
    │           ▼
    │     Optimistic UI Update (immediate)
    │
    ▼
Abstract Service Interface
    │
    ├──► MockService (current)
    │         │
    │         ▼
    │    Hive Local Box ◄──────── App Start Seed
    │
    └──► FirebaseService (future)
              │
              ▼
         Firestore ──► snapshots() stream ──► Provider ──► UI
```

**Key principle**: The UI never waits for I/O. Every write is applied optimistically in the Provider's in-memory state first, then persisted to Hive. When Firestore is integrated, writes will be mirrored there; the Firestore `snapshots()` stream will drive real-time sync between the Trainer and Guru apps.

---

## 3. Provider Tree

### Guru App (`guru_app`)

```
MultiProvider
├── Provider<AuthService>          ← MockAuthService (future: FirebaseAuthService)
├── Provider<ChatService>          ← MockChatService (future: FirebaseChatService)
├── Provider<ScheduleService>      ← MockScheduleService (future: FirebaseScheduleService)
├── Provider<CallService>          ← MockCallService (future: 100ms-backed CallService)
├── ChangeNotifierProvider<AuthProvider>      (depends on AuthService)
├── ChangeNotifierProvider<ChatProvider>      (depends on ChatService)
├── ChangeNotifierProvider<ScheduleProvider>  (depends on ScheduleService)
└── ChangeNotifierProvider<CallProvider>      (depends on CallService, token server)
```

### Trainer App (`trainer_app`)

```
MultiProvider
├── Provider<AuthService>          ← MockAuthService
├── Provider<ChatService>          ← MockChatService
├── Provider<SessionService>       ← MockSessionService
├── Provider<CallService>          ← MockCallService
├── ChangeNotifierProvider<AuthProvider>
├── ChangeNotifierProvider<ChatProvider>
├── ChangeNotifierProvider<SessionProvider>
└── ChangeNotifierProvider<CallProvider>
```

Services are **constructor-injected** into Providers — no global singletons. This keeps Providers testable in isolation by passing mock services directly.

---

## 4. 100ms Call Lifecycle

```
[Member taps "Request Call"]
        │
        ▼
CallProvider.requestCall(trainerId)
        │
        ▼
CallService.createCallRequest(CallRequestModel)
        │  stored in Hive call_requests_box
        ▼
[Trainer sees pending request in DashboardScreen]
        │
        ▼
CallProvider.approveCall(requestId)
        │
        ▼
HTTP GET /token?userId=trainer_001&role=trainer
        │  token_server signs JWT with HMS_ACCESS_KEY + HMS_SECRET
        ▼
CallProvider receives { token, roomId }
        │
        ▼
HMSSDK.build() → HMSSDK.join(config)
        │  config = HMSConfig(authToken: token, roomId: roomId, ...)
        ▼
[Both users in call — video/audio via 100ms WebRTC]
        │
        ▼
CallProvider.leaveCall() or room-end event
        │
        ▼
LogService.writeSessionLog(SessionLogModel)
        │  stored in Hive session_logs_box
        ▼
[SessionLogScreen shows past calls]
```

**Stub behaviour**: Until 100ms credentials are configured, `CallProvider` receives `dev-stub-token` from the token server and logs a warning. The call UI still renders; HMSSDK join is skipped.

---

## 5. Chat Message Flow

```
[User types message, taps Send]
        │
        ▼
ChatProvider.sendMessage(text)
        │
        ├──► 1. Append MessageModel(status: sending) to in-memory list
        │              notifyListeners() → UI renders optimistically
        │
        ├──► 2. ChatService.saveMessage(message) → Hive messages_box
        │
        └──► 3. (future) FirebaseChatService.push(message) → Firestore
                         │
                         ▼
                   Firestore snapshots()
                         │
                         ▼
                   ChatProvider._onSnapshot() → update list → notifyListeners()
                         │
                         ▼
                   ConversationScreen rebuilds with confirmed message
```

**Why optimistic updates?** On slow/offline networks the UI feels instant. The message is written to Hive immediately so it survives app restart. Firestore sync happens in the background; if it fails, a retry queue (future work) will handle delivery.

---

## 6. Hive Boxes

| Box Name              | TypeId Range | Contents                              | Used By              |
|-----------------------|-------------|---------------------------------------|----------------------|
| `users_box`           | 0           | `UserModel` — all seeded users        | AuthService          |
| `messages_box`        | 1           | `MessageModel` — all chat messages    | ChatService          |
| `call_requests_box`   | 2           | `CallRequestModel` — pending calls    | CallService          |
| `session_logs_box`    | 3           | `SessionLogModel` — completed calls   | LogService           |
| `room_meta_box`       | 4           | `RoomMetaModel` — 100ms room metadata | CallService          |
| `prefs_box`           | —           | Raw key-value (no adapter needed)     | AuthService (userId) |

**Enum adapters** (typeId 10–12):
- `UserRoleAdapter` (typeId: 10)
- `MessageTypeAdapter` (typeId: 11)
- `CallStatusAdapter` (typeId: 12)

All adapters are registered in `HiveConfig.init()`, called before `runApp()` to avoid `unknown typeId` errors.

---

## 7. Service Layer Design

### Pattern: Abstract Interface → Mock → Firebase

```dart
// shared/lib/services/auth_service.dart
abstract class AuthService {
  Stream<UserModel?> get authStateChanges;
  Future<UserModel?> signIn(String email, String password);
  Future<void> signOut();
  Future<UserModel?> currentUser();
}

// shared/lib/services/mock_auth_service.dart
class MockAuthService implements AuthService {
  // Hive-backed, seeded with Aarav (trainer) and DK (member)
}

// shared/lib/services/firebase_auth_service.dart  ← future
class FirebaseAuthService implements AuthService {
  // FirebaseAuth.instance + Firestore user doc lookup
}
```

The same pattern applies to `ChatService`, `ScheduleService`, `CallService`, and `LogService`.

**Why abstract interfaces?**

- The Provider only knows about the abstract type — it never imports Mock or Firebase directly
- Switching from Mock to Firebase requires only changing the `Provider<AuthService>` binding in `main.dart`
- Unit tests can inject a `FakeAuthService` without any platform setup

### Mock Data Seed

On first launch, `MockAuthService` checks if `users_box` is empty and seeds:

| userId       | name  | email         | role    | assignedTrainerId |
|--------------|-------|---------------|---------|-------------------|
| `trainer_001`| Aarav | aarav@wtf.com | trainer | —                 |
| `member_001` | DK    | dk@wtf.com    | member  | trainer_001       |

This allows the full app flow (login → chat → schedule → call) to work without a backend.
