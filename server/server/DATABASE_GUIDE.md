# Carrom Champions - User Database & Persistence Guide (Phase 1)

This module provides cloud-ready user persistence, authentication, coin economy, and match recording for **Carrom Champions**.

---

## 1. Architecture Overview

- **Storage Engine:** Atomic JSON document store (`server/data/users.json`) with in-memory Maps for zero-latency ($<0.1\text{ ms}$) lookups.
- **Production Migration Ready:** Includes [schema.sql](file:///F:/carromweb/server/schema.sql) compatible with **Google Cloud SQL (PostgreSQL)**, **Supabase**, and **MySQL**.
- **Unified Backend:** The database connects directly to both the **HTTP REST API** and **WebSockets (ws)**.

---

## 2. User Data Model

Each user record contains:
```json
{
  "userId": "usr_6a6bf116b457",
  "username": "ChampionArun",
  "deviceId": "android_phone_007",
  "coins": 1000,
  "matchesPlayed": 12,
  "matchesWon": 8,
  "unlockedCrackers": ["classic_sparkler", "golden_sparkler", "flower_pot_gold"],
  "equippedStriker": "default",
  "createdAt": "2026-10-27T10:23:11.194Z",
  "lastActive": "2026-10-27T10:25:00.000Z"
}
```

---

## 3. Database REST API Endpoints

### `POST /api/auth/login`
Logs in an existing user or creates a new user profile with **1,000 Free Welcome Coins**.
* **Request:**
  ```json
  { "username": "ChampionArun", "deviceId": "dev_android_123" }
  ```
* **Response:**
  ```json
  {
    "success": true,
    "user": { ... }
  }
  ```

### `POST /api/user/sync`
Synchronizes player stats, unlocked crackers from the Cracker Bazaar, or equipped striker.
* **Request:**
  ```json
  {
    "userId": "usr_6a6bf116b457",
    "coins": 1250,
    "unlockedCrackers": ["classic_sparkler", "golden_sparkler"]
  }
  ```

### `GET /api/user/profile?userId=...`
Retrieves live database stats for a player.

### `GET /api/leaderboard`
Returns the top 15 players ranked by **Matches Won** and **Coins**.

---

## 4. WebSocket Database Collaboration

When a player enters the **ONLINE PLAY** lobby or creates/joins a room:
1. The client sends `USER_LOGIN` with their `userId` and `deviceId`.
2. The server binds their WebSocket connection to their database account.
3. Every player in the room sees the host and guests' **live coin balances** and **avatars**.
4. When a match ends (`MATCH_FINISHED`), the server awards:
   - **Winner:** +300 Coins
   - **Participants:** +50 Coins
   And updates their `matchesWon` and `matchesPlayed` in the database immediately.
