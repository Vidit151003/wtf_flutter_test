# WTF Token Server

A lightweight Node.js/Express server that generates **100ms management tokens** for Flutter apps in the WTF Flutter Test project. It signs JWT tokens using your 100ms credentials and returns them to the requesting app so it can join a 100ms room.

---

## Purpose

The Flutter apps (`guru_app`, `trainer_app`) cannot safely store the 100ms `HMS_SECRET` inside the app bundle. This server acts as a secure intermediary:

1. The Flutter app calls `GET /token?userId=<id>&role=<role>`
2. This server signs a JWT with your 100ms credentials
3. The app receives the token and passes it to `HMSSDK.join()`

---

## Prerequisites

- **Node.js 18+** — [Download](https://nodejs.org/)
- **npm** (bundled with Node.js)
- A **100ms account** — [dashboard.100ms.live](https://dashboard.100ms.live)

---

## Setup

### 1. Install dependencies

```bash
cd token_server
npm install
```

### 2. Configure environment variables

```bash
cp .env.example .env
```

Open `.env` and fill in your credentials:

```env
HMS_ACCESS_KEY=your_100ms_access_key_here
HMS_SECRET=your_100ms_secret_here
DEV_FALLBACK_ROOM_ID=dev-room-001
PORT=3000
```

### 3. How to get HMS_ACCESS_KEY and HMS_SECRET

1. Log in to [https://dashboard.100ms.live](https://dashboard.100ms.live)
2. Go to **Developer** → **Access Credentials** in the left sidebar
3. Copy the **Access Key** → paste as `HMS_ACCESS_KEY`
4. Copy the **Secret** → paste as `HMS_SECRET`
5. Create a room template with a `trainer` role and a `member` role
6. Copy a Room ID from **Rooms** → paste as `DEV_FALLBACK_ROOM_ID`

---

## Running the Server

```bash
node index.js
```

For development with auto-restart on file changes:

```bash
npm run dev
```

The server starts at `http://localhost:3000` by default.

---

## API Reference

### `GET /token`

Generates a 100ms management JWT for the requesting user.

**Query Parameters**

| Parameter | Required | Description                          |
|-----------|----------|--------------------------------------|
| `userId`  | ✅ Yes   | Unique identifier for the user       |
| `role`    | ✅ Yes   | 100ms role name (e.g. `trainer`, `member`) |

**Success Response — `200 OK`**

```json
{
  "token": "<signed_jwt>",
  "roomId": "dev-room-001"
}
```

**Error Responses**

| Status | Reason                          |
|--------|---------------------------------|
| `400`  | Missing `userId` or `role` param |
| `500`  | JWT signing failed (server error)|

**Example**

```bash
curl "http://localhost:3000/token?userId=trainer_001&role=trainer"
```

---

### `GET /health`

Simple health check endpoint.

**Response — `200 OK`**

```json
{ "status": "ok" }
```

---

## Dev Stub Behaviour (No Credentials)

If `HMS_ACCESS_KEY` or `HMS_SECRET` are **not set** in `.env`, the server will **not crash**. Instead it returns a stub response so Flutter development can continue without real credentials:

```json
{
  "token": "dev-stub-token",
  "roomId": "dev-room-001",
  "warning": "100ms credentials not configured — using dev stub"
}
```

A warning is logged to the console:

```
[RTC] HMS credentials not configured. Set HMS_ACCESS_KEY and HMS_SECRET in .env
```

This allows the rest of the app (UI, navigation, state management) to be developed and tested before 100ms is fully configured.

---

## Token Details

| Field         | Value                                   |
|---------------|-----------------------------------------|
| Algorithm     | `HS256`                                 |
| Expiry        | 24 hours from issue time                |
| `type`        | `management`                            |
| `version`     | `2`                                     |
| `jti`         | `<userId>-<timestamp>` (unique per call)|

---

## Notes

- The `.env` file is **gitignored** — never commit real credentials.
- For production, deploy this server behind HTTPS and restrict CORS origins.
- Firebase Authentication integration is planned; this server will eventually validate a Firebase ID token before issuing the 100ms token.
