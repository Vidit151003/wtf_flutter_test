# WTF Flutter Test

Two Flutter apps — **Guru App** (member-facing) and **Trainer App** — sharing a common Dart package, backed by a local-first architecture with Hive and a Node.js 100ms token server.

## Architecture

- `shared/` — Models, services, widgets, utils
- `guru_app/` — Member-facing Flutter app
- `trainer_app/` — Trainer-facing Flutter app
- `token_server/` — Node.js 100ms token server

## Quick Start

### 1. Token Server (optional — 100ms integration pending)

```bash
cd token_server
npm install
cp .env.example .env
# Fill HMS_ACCESS_KEY and HMS_SECRET from https://dashboard.100ms.live
node index.js
```

### 2. Guru App

```bash
cd guru_app
flutter pub get
flutter run
```

### 3. Trainer App

```bash
cd trainer_app
flutter pub get
flutter run
```

## Firebase Setup (pending)

> Place `google-services.json` from your Firebase project into:
> - `guru_app/android/app/google-services.json`
> - `trainer_app/android/app/google-services.json`
>
> Then update `pubspec.yaml` to include `firebase_core` and `cloud_firestore`.

## Test Credentials

| Role    | Name  | Email          | Password       |
|---------|-------|----------------|----------------|
| Trainer | Aarav | aarav@wtf.com  | any            |
| Member  | DK    | dk@wtf.com     | — (auto-created) |

## Docs

- Architecture overview → [ARCHITECTURE.md](./ARCHITECTURE.md)
- State management decisions → [DECISIONS.md](./DECISIONS.md)
- AI usage log → [AI_LEDGER.md](./AI_LEDGER.md)
