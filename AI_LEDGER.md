# AI Ledger — WTF Flutter Test

This file logs all AI-assisted development sessions: prompts used, outputs received, modifications made, and commit references.

---

## Prompt #1
- **Tool**: Claude (Anthropic)
- **Intent**: Generate Hive model boilerplate for all 5 data models
- **Prompt Used**: "Generate null-safe Dart 3.x Hive-compatible models for UserModel, MessageModel, CallRequestModel, SessionLogModel, and RoomMetaModel with typeId annotations, fromJson/toJson, copyWith, and Equatable..."
- **Output Summary**: Generated all 5 models with HiveType/HiveField annotations, Equatable props, fromJson/toJson factory constructors, and copyWith methods. Also generated manual .g.dart adapter files.
- **Commit**: `feat: add all 5 hive data models with adapters`
- **Notes**: Adjusted typeId ordering to avoid conflicts (enums use 10-12, models use 0-4).

---

## Prompt #2 — Debugging
- **Tool**: Claude
- **Error**: `HiveError: Cannot read, unknown typeId 3`
- **AI Steps**: Suggested re-running build_runner and verifying that all adapters are registered in the correct order before `Hive.openBox`.
- **Resolution**: Moved adapter registration to a dedicated `HiveConfig.init()` method called before `runApp()`. Changed RoomMeta typeId from 3 to 4 to avoid conflict with SessionLog.
- **Commit**: `fix: resolve hive typeId conflict in room_meta_model`

---

## Prompt #3
- **Tool**: Claude
- **Intent**: Generate abstract service interfaces and MockAuthService with seeded data
- **Prompt Used**: "Create an abstract AuthService class and MockAuthService implementation in Dart. Seed with Aarav (trainer_001, trainer role) and DK (member_001, member role, assignedTrainerId: trainer_001). Use Hive for persistence, StreamController for authStateChanges..."
- **Output Summary**: Generated abstract `AuthService` interface and `MockAuthService` with StreamController, Hive `prefs_box` persistence, and seeded users.
- **Commit**: `feat: add auth service with mock implementation and seeded data`
- **Notes**: Added AppLogger.log calls at every method entry/exit.

---

## Prompt #4
- **Tool**: Claude
- **Intent**: Design the Provider tree architecture for both apps
- **Prompt Used**: "Design a MultiProvider setup for guru_app and trainer_app using Provider + ChangeNotifier. Each app needs AuthProvider, ChatProvider, ScheduleProvider (guru only), SessionProvider, and CallProvider. Services injected via constructor..."
- **Output Summary**: Generated MultiProvider setup in app.dart for both apps, with service instances passed to providers via constructor injection.
- **Commit**: `feat: set up provider tree in both apps`
- **Notes**: Decided against global singleton services — all services injected for testability.

---

## Prompt #5
- **Tool**: Claude
- **Intent**: Generate ConversationScreen with optimistic message updates and typing indicator
- **Prompt Used**: "Build a Flutter ConversationScreen with ChatProvider, optimistic UI updates, 3-dot typing indicator animation, quick reply chips, auto-scroll to bottom on new message, and pull-to-refresh shimmer..."
- **Output Summary**: Generated ConversationScreen as StatefulWidget with AnimationController for typing dots, ListView.builder(reverse: true), TextEditingController, and FocusNode management.
- **Commit**: `feat: add conversation screen with typing indicator and quick replies`
- **Notes**: Used SingleTickerProviderStateMixin for typing animation.

---

## Prompt #6
- **Tool**: Claude
- **Intent**: Build time slot grid for ScheduleScreen
- **Prompt Used**: "Create a Flutter GridView of 30-minute time slots from 8:00 AM to 8:00 PM. Past slots should be greyed out and non-tappable. Selected slot should highlight with primary color. Slots for the next 3 days selectable via horizontal date chips..."
- **Output Summary**: Generated date chip row and time slot grid with past-time detection logic.
- **Commit**: `feat: add schedule screen with time slot grid`
- **Notes**: Used `DateTime.now()` comparison for disabling past slots, added haptic feedback on slot selection.

---

## Prompt #7
- **Tool**: Claude
- **Intent**: Implement 100ms HMSSDK stub for CallProvider
- **Prompt Used**: "Create a CallProvider extending ChangeNotifier that wraps HMSSDK. Include joinCall, leaveCall, toggleMic, toggleCamera, flipCamera. On room end, write SessionLogModel via LogService. Handle reconnect up to 3 times with 2s delay..."
- **Output Summary**: Generated CallProvider with HMSUpdateListener implementation, reconnect logic, session log writing on call end.
- **Commit**: `feat: add call provider with hmssdk integration stub`
- **Notes**: 100ms SDK integration is stubbed — credentials and actual SDK import pending.

---

## Prompt #8
- **Tool**: Claude
- **Intent**: Build AppTheme with dual-brand color system
- **Prompt Used**: "Create an AppTheme utility in Flutter with two ThemeData instances: Trainer (primary #E50914) and Guru (primary #1769E0). Include 8pt spacing system constants, shared success/warning/error colors, and typography scale..."
- **Output Summary**: Generated AppTheme with both ThemeData, ColorScheme, TextTheme, and kSpacing constants.
- **Commit**: `feat: add dual-brand app theme with spacing system`
- **Notes**: Used ColorScheme.fromSeed for both themes to ensure Material 3 compliance.

---

## Prompt #9 — Debugging
- **Tool**: Claude
- **Error**: `flutter analyze` reported `unused_import` and `prefer_const_constructors` in multiple files
- **AI Steps**: Ran `flutter analyze --no-pub` in both apps, listed all issues, applied fixes systematically.
- **Resolution**: Removed unused imports, added `const` to constructors, replaced string interpolations with adjacent string literals where appropriate.
- **Commit**: `fix: resolve all flutter analyze warnings across both apps`

---

## Prompt #10
- **Tool**: Claude
- **Intent**: Generate unit tests for models and validators
- **Prompt Used**: "Write flutter test unit tests for: (1) MessageModel JSON round-trip, (2) Validators.validateScheduleTime with past/future/boundary cases, (3) int.toFormattedDuration extension..."
- **Output Summary**: Generated 3 test files with 8 total test cases covering all specified scenarios.
- **Commit**: `test: add model serialization, validator, and duration format tests`
- **Notes**: All tests pass on `flutter test`.

---

## Prompt #11
- **Tool**: Claude
- **Intent**: Add DevPanelOverlay to both apps
- **Prompt Used**: "Create a FloatingActionButton overlay that opens a bottom sheet showing: app name/version (package_info_plus), build mode, last 20 AppLogger entries with color-coded tags, and a Clear Logs button..."
- **Output Summary**: Generated DevPanelOverlay widget using Stack + Positioned, BottomSheet with log viewer.
- **Commit**: `feat: add dev panel overlay to both apps`
- **Notes**: DevPanel only visible in debug mode via `kDebugMode` check.

---

## Prompt #12 — Debugging
- **Tool**: Claude
- **Error**: `RangeError: Invalid value: Not in inclusive range 1..5: 0` in SessionLogTile star rating
- **AI Steps**: Added null check on `log.rating` before rendering stars, used `?.let` pattern.
- **Resolution**: Wrapped star row in `if (log.rating != null)` conditional.
- **Commit**: `fix: guard null rating in session log tile`
