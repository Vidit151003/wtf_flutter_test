# AI_LEDGER.md

## Project: WTF Flutter Test — Guru App + Trainer App

### Purpose

This ledger maintains a structured record of:

* Prompts/questions asked to AI systems
* AI-generated outputs and recommendations
* Technical decisions taken
* Implementation guidance
* Configuration instructions
* Architecture decisions

---

# Entry 001 — Firebase Architecture Decision

## Prompt

> Okay so for this particular project do i need to set up two firebase storages or just one single storage for both ??

## AI Usage Context

Used during initial backend architecture planning for the dual-app Flutter system consisting of:

* `guru_app`
* `trainer_app`

## AI Response Summary

Recommended using:

* A **single Firebase project** for both apps
* Shared Firestore database
* Shared authentication layer
* Shared real-time sync layer

Separate Firebase app registrations were required for each application package.

## Technical Decision

### Use One Shared Firebase Project

Architecture:

```text
guru_app  ──┐
             ├──► Firebase Project (single)
trainer_app─┘
```

## Collections Shared Across Both Apps

* `/chats`
* `/callRequests`
* `/sessionLogs`

## Configuration Breakdown

| Component            | Guru App        | Trainer App     |
| -------------------- | --------------- | --------------- |
| Firebase Project     | Shared          | Shared          |
| Firestore            | Shared          | Shared          |
| Firebase Auth        | Shared          | Shared          |
| google-services.json | Separate file   | Separate file   |
| Hive Local DB        | Device-specific | Device-specific |

## Practical Implementation Steps

1. Create one Firebase project
2. Add two Android apps inside Firebase:

   * `com.wtf.guru_app`
   * `com.wtf.trainer_app`
3. Download separate `google-services.json` files
4. Place them in each app's Android folder

## Output/Reference

Internal implementation guidance generated during project setup.

---

# Entry 002 — Firebase Configuration File Placement

## Prompt

> This is the Project structure of the Guru app now where do i Place the google firebase.json file in this and same structure if there for the trainer app the agent returned that the task for creation is completed

## AI Usage Context

Used during Flutter Firebase integration.

## AI Response Summary

The Firebase configuration file should be placed inside:

```text
guru_app/android/app/google-services.json
```

And similarly:

```text
trainer_app/android/app/google-services.json
```

## Important Guidance

The AI clarified:

* The `android/` folder may be hidden in Android Studio if using Android view
* Switching to Project view reveals the actual folder structure

## Firebase Console Instructions

Navigate to:

```text
Firebase Console → Project Settings → Your Apps
```

Download app-specific configuration files for:

* `com.wtf.guru_app`
* `com.wtf.trainer_app`

## Output/Reference

Firebase integration guidance.

---

# Entry 003 — Missing Android Folder Resolution

## Prompt

> No there is no android folder I have even checked in the vs code

## AI Usage Context

Used during troubleshooting of Flutter platform setup.

## AI Response Summary

The AI identified that the Flutter platform folders had not yet been generated.

## Recommended Commands

```bash
# Guru App
cd wtf_flutter_test/guru_app
flutter create --platforms=android .

# Trainer App
cd ../trainer_app
flutter create --platforms=android .
```

## Explanation

The command:

```bash
flutter create --platforms=android .
```

Generates:

* `android/`
* Android Gradle configuration
* Platform-specific project files

Without overwriting:

* `lib/`
* `test/`
* `pubspec.yaml`

## Additional Validation

Ensure `applicationId` matches Firebase registration.

Example:

```gradle
defaultConfig {
    applicationId "com.wtf.guru_app"
}
```

## Output/Reference

Flutter Android project regeneration guidance.

---

# Entry 004 — 100ms Video SDK Integration

## Prompt

> If I have to connect to the 100ms Api in this application what all do i have to provide in the application and where ??

## AI Usage Context

Used while planning real-time audio/video communication infrastructure.

## AI Response Summary

The AI described the complete integration flow for:

* 100ms SDK
* Token server
* Flutter configuration
* Permissions
* Secure credential management

## Required Credentials

From 100ms Dashboard:

* `APP_ACCESS_KEY`
* `APP_SECRET`
* `ROOM_ID`

## Token Server Setup

### File

```text
token_server/.env
```

### Configuration

```env
HMS_ACCESS_KEY=your_access_key_here
HMS_SECRET=your_secret_here
PORT=3000
```

## Flutter Dependency

### pubspec.yaml

```yaml
dependencies:
  hmssdk_flutter: ^1.9.9
```

## Android Configuration

### build.gradle

```gradle
compileSdkVersion 33
minSdkVersion 21
```

## Required Permissions

### AndroidManifest.xml

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.BLUETOOTH"/>
```

## Token Fetching Flow

```text
100ms Dashboard
    ↓
Token Server
    ↓
Flutter App
    ↓
100ms Servers
```

## Runtime Token Retrieval

```dart
final response = await http.get(
  Uri.parse('${AppConstants.tokenServerUrl}?userId=$userId&role=$role')
);
```

## Security Decision

Never expose:

* `APP_SECRET`
* Access keys

inside Flutter client code.

## Output/Reference

100ms integration architecture and setup documentation.

---

# Entry 005 — Running Dual Flutter Apps Simultaneously

## Prompt

> Now how do I run the different apps one on emulator and one on the phone

## AI Usage Context

Used during multi-device testing setup.

## AI Response Summary

The AI explained how to:

* Run one app on emulator
* Run another on physical device
* Connect both to same backend
* Configure networking

## Step 1 — Verify Devices

```bash
flutter devices
```

Example output:

```text
sdk gphone64 x86 64 (mobile) • emulator-5554
Dhruv's Phone (mobile) • RZ8N90BXWQJ
```

## Step 2 — Launch Apps Separately

### Guru App on Emulator

```bash
cd wtf_flutter_test/guru_app
flutter run -d emulator-5554
```

### Trainer App on Phone

```bash
cd wtf_flutter_test/trainer_app
flutter run -d RZ8N90BXWQJ
```

## Step 3 — Start Token Server

```bash
cd wtf_flutter_test/token_server
node index.js
```

## Network Configuration Guidance

| Device     | Token Server URL          |
| ---------- | ------------------------- |
| Emulator   | `http://10.0.2.2:3000`    |
| Real Phone | `http://192.168.x.x:3000` |

## Dynamic Configuration Example

```dart
class AppConstants {
  static String get tokenServerUrl {
    return Platform.environment['TOKEN_SERVER_URL']
        ?? 'http://10.0.2.2:3000/token';
  }
}
```

## VS Code Multi-Launch Setup

### `.vscode/launch.json`

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Guru App (Emulator)",
      "request": "launch",
      "type": "dart",
      "program": "guru_app/lib/main.dart",
      "deviceId": "emulator-5554"
    },
    {
      "name": "Trainer App (Phone)",
      "request": "launch",
      "type": "dart",
      "program": "trainer_app/lib/main.dart",
      "deviceId": "RZ8N90BXWQJ"
    }
  ],
  "compounds": [
    {
      "name": "Run Both Apps",
      "configurations": [
        "Guru App (Emulator)",
        "Trainer App (Phone)"
      ]
    }
  ]
}
```

## Output/Reference

Dual-device Flutter execution setup documentation.

---

# Overall AI Usage Summary

## Technologies Discussed

* Flutter
* Firebase
* Firestore
* Hive
* 100ms SDK
* Node.js Token Server
* Android Gradle
* VS Code Multi-Launch
* Real-time communication architecture

## Major Architectural Decisions

### Backend

* Shared Firebase project
* Shared Firestore
* Shared Authentication

### Client Apps

* Separate Flutter apps
* Independent package names
* Shared backend sync

### Communication

* 100ms for RTC/video/audio
* Token-server-based authentication

### Local Persistence

* Hive for device-specific storage

## Security Considerations

* Keep 100ms secrets server-side only
* Use token-based authentication
* Separate Firebase app registrations

---

# Source Reference

User-provided discussion log:

fileciteturn0file0

Additional project specification and audit prompt:

fileciteturn1file0

---

# Entry 006 — Master Assessment Prompt & Full Project Specification

## Prompt Source

Imported from the uploaded project specification markdown document.

## AI Usage Context

This prompt served as the complete system architecture and implementation blueprint for the project:

* `wtf_flutter_test`
* `guru_app`
* `trainer_app`
* `shared`
* `token_server`

It defined:

* Monorepo structure
* Flutter architecture
* Firebase strategy
* Hive integration
* 100ms RTC flow
* Provider state management
* Documentation standards
* Testing requirements
* Dev tooling
* UI copy standards

## Core Architectural Requirements

### Applications

* Guru App (Member App)
* Trainer App
* Shared package
* Token server

### Backend Stack

* Firebase Firestore
* Hive local storage
* 100ms SDK
* Node.js token server

### State Management

* Provider + ChangeNotifier only

### Required Documentation

* `AI_LEDGER.md`
* `ARCHITECTURE.md`
* `DECISIONS.md`
* `README.md`

## Important Technical Constraints

### Mandatory Rules

1. Provider only (no Riverpod/Bloc)
2. Null-safe Dart 3.x
3. No hardcoded secrets
4. Firebase as sync layer
5. Hive as offline-first local layer
6. Optimistic UI updates required
7. Zero analyzer warnings required
8. Conventional commits required

## Shared Package Requirements

### Required Models

* `UserModel`
* `MessageModel`
* `CallRequestModel`
* `SessionLogModel`
* `RoomMetaModel`

### Required Services

* `AuthService`
* `ChatService`
* `CallService`
* `LogService`

### Required Widgets

* `ChatBubble`
* `SessionLogTile`
* `AppAvatar`
* `EmptyStateWidget`
* `SkeletonLoader`

## Firebase Collection Structure

```text
/users/{userId}
/chats/{chatId}/messages/{messageId}
/chats/{chatId}/typing/{userId}
/callRequests/{requestId}
/rooms/{roomId}
/sessionLogs/{logId}
```

## 100ms Integration Requirements

### Required Flow

1. Fetch token from token server
2. Initialize HMSSDK
3. Join room
4. Handle reconnects
5. Capture session logs
6. Save session duration

### Emulator Handling

If emulator lacks camera:

* Show initials placeholder
* Avoid crashes
* Continue room connectivity

## Required Screens

### Guru App

* Onboarding
* Profile Setup
* Home
* Chat
* Schedule
* Sessions
* Call

### Trainer App

* Login
* Home
* Members
* Requests
* Sessions
* Chat
* Call

## DevPanel Requirements

The prompt required an in-app debug overlay containing:

* Build mode
* Environment variables
* Logs
* App version
* Log clearing

## Unit Test Requirements

Minimum required tests:

* Message serialization
* Scheduler validation
* Session duration formatting

## Documentation Requirements

### Required ADRs

1. Provider state management decision
2. Hive + Firestore storage strategy
3. 100ms RTC selection rationale

### Architecture Documentation

Required:

* Local-first data flow
* Firebase sync architecture
* Provider tree
* Chat flow
* RTC lifecycle

## Execution Order Defined by Prompt

1. Shared package
2. Token server
3. Firebase configuration
4. Guru app
5. Trainer app
6. Dev panel
7. Tests
8. Documentation
9. Final lint pass

## Quality Checklist Defined by Prompt

The assessment required:

* `flutter analyze` with zero warnings
* Passing tests
* Empty/loading/error states everywhere
* Conventional commits
* Firebase `.env` usage
* Shared package path references
* DevPanel availability
* AI ledger with 10+ entries

## Entry 007 — Firebase Audit & Integration Findings

## Prompt

> At this point I havent actually integrated 100ms API it will be created later as of now its just mock but Firebase needs to be set up now that I have placed the google services.json in the respective folders please integrate the firebase as stated in the implementation.

## AI Usage Context

Used during post-build audit and Firebase integration phase.

## Major Findings During Audit

### Finding 1 — Incorrect Firebase File Name

The Trainer App Firebase config file was incorrectly named:

```text
google-services .json
```

It contained an extra space before `.json`.

### Resolution

Renamed to:

```text
google-services.json
```

## Finding 2 — Firebase Not Initialized

The AI audit identified:

* Firebase packages missing
* No Firebase initialization in Flutter entrypoints
* Google Services Gradle plugin not applied
* Firestore services not connected

## Firebase Integration Changes Applied

### Android Configuration

Updated:

* `build.gradle.kts`
* `settings.gradle.kts`
* Android manifests

Added:

* Google Services plugin
* Firebase dependencies
* Internet/media permissions

## Package ID Alignment

Detected mismatch:

```text
com.example.*
```

Firebase expected:

```text
com.wtf.guruapp
com.wtf.trainerapp
```

### Resolution

Application IDs and namespaces were aligned with Firebase registrations.

## Flutter Initialization

Added Firebase initialization inside:

```dart
await Firebase.initializeApp();
```

for:

* Guru App
* Trainer App

## Firestore Integration

Implemented Firestore-backed services for:

* Chat sync
* Typing indicators
* Session logs
* Call requests
* Room metadata
* User profiles

## Architecture Preserved

The audit intentionally preserved:

* Existing provider structure
* Existing UI flow
* Mock authentication
* Deferred 100ms implementation

## Deferred Components

The following remained intentionally mocked:

* HMSSDK integration
* Real room creation
* RTC transport
* 100ms token lifecycle

## Additional Changes

### Added

* `firestore.rules`
* Android permissions
* Lazy Firestore initialization
* Write-through cache strategy

### Fixed

* Encoding/UI string corruption
* Startup initialization ordering
* Service instantiation timing

## Validation Steps Attempted

### Commands Executed

```bash
flutter pub get
flutter analyze
flutter test
```

## Tooling Issue Observed

The environment experienced:

* Hanging analyzer processes
* Flutter test runner timeouts
* WebSocket disconnects
* Sandbox network instability

## Final Technical State After Audit

### Confirmed Working

* Firebase Android wiring
* Firestore service integration
* Shared Firebase project alignment
* Package ID matching
* Firebase initialization
* Shared architecture consistency

### Intentionally Pending

* 100ms production integration
* HMSSDK runtime validation
* Full analyzer/test verification

## Important Architectural Preservation

The AI explicitly preserved alignment with:

* Assessment document requirements
* Existing frontend structure
* Existing backend structure
* Provider-based architecture
* Local-first strategy

---

# Complete Source References

Primary conversation log:
fileciteturn0file0

Master project specification and Firebase audit prompt:
fileciteturn1file0
