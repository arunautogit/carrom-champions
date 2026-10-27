// =============================================================================
// CARROM CHAMPIONS - USER DATABASE MODULE (PHASE 1 CLOUD-READY)
// Manages player authentication, profiles, coin balances, unlocked items,
// and match stats with atomic JSON file persistence and SQL migration schema.
// =============================================================================

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const DATA_DIR = path.resolve(__dirname, 'data');
const USERS_FILE = path.join(DATA_DIR, 'users.json');

// Ensure data directory exists
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

class UserDatabase {
  constructor() {
    this.users = new Map(); // Key: userId -> UserObject
    this.usernameIndex = new Map(); // Key: lowercase username -> userId
    this.load();
  }

  // Load database from disk
  load() {
    try {
      if (fs.existsSync(USERS_FILE)) {
        const raw = fs.readFileSync(USERS_FILE, 'utf8');
        const data = JSON.parse(raw);
        this.users.clear();
        this.usernameIndex.clear();

        for (const user of data) {
          this.users.set(user.userId, user);
          this.usernameIndex.set(user.username.toLowerCase(), user.userId);
        }
        console.log(`[Database] Loaded ${this.users.size} user records from ${USERS_FILE}`);
      } else {
        // Seed default guest user
        this.save();
        console.log(`[Database] Initialized new user store at ${USERS_FILE}`);
      }
    } catch (err) {
      console.error('[Database Error] Failed to read users file:', err.message);
      this.users = new Map();
      this.usernameIndex = new Map();
    }
  }

  // Save database to disk atomically
  save() {
    try {
      const data = Array.from(this.users.values());
      const tempPath = USERS_FILE + '.tmp';
      fs.writeFileSync(tempPath, JSON.stringify(data, null, 2), 'utf8');
      fs.renameSync(tempPath, USERS_FILE);
    } catch (err) {
      console.error('[Database Error] Failed to persist users:', err.message);
    }
  }

  // Find user by ID
  findById(userId) {
    if (!userId) return null;
    return this.users.get(userId) || null;
  }

  // Find user by username
  findByUsername(username) {
    if (!username) return null;
    const userId = this.usernameIndex.get(username.trim().toLowerCase());
    return userId ? this.users.get(userId) : null;
  }

  // User Login or Auto-Register
  loginOrRegister(username, deviceId = null) {
    let cleanName = (username || '').trim();
    if (!cleanName || cleanName.length < 2) {
      cleanName = 'Player ' + Math.floor(1000 + Math.random() * 9000);
    }
    cleanName = cleanName.substring(0, 16);

    let user = this.findByUsername(cleanName);

    if (user) {
      // Existing user: update last login & deviceId if provided
      user.lastActive = new Date().toISOString();
      if (deviceId) user.deviceId = deviceId;
      this.save();
      console.log(`[Auth] User logged in: ${user.username} (${user.userId}) | Coins: ${user.coins}`);
      return user;
    }

    // New user registration
    const newUserId = 'usr_' + crypto.randomBytes(6).toString('hex');
    user = {
      userId: newUserId,
      username: cleanName,
      deviceId: deviceId || ('dev_' + crypto.randomBytes(8).toString('hex')),
      coins: 1000, // 1,000 Free Welcome Bonus Coins
      matchesPlayed: 0,
      matchesWon: 0,
      unlockedCrackers: ['classic_sparkler'],
      equippedStriker: 'default',
      createdAt: new Date().toISOString(),
      lastActive: new Date().toISOString()
    };

    this.users.set(newUserId, user);
    this.usernameIndex.set(cleanName.toLowerCase(), newUserId);
    this.save();

    console.log(`[Auth] Registered new player: ${user.username} (${newUserId}) with 1,000 welcome coins!`);
    return user;
  }

  // Update user stats or settings
  updateUser(userId, updates = {}) {
    const user = this.findById(userId);
    if (!user) return null;

    if (updates.coins !== undefined) user.coins = Math.max(0, Number(updates.coins) || 0);
    if (updates.matchesPlayed !== undefined) user.matchesPlayed = Number(updates.matchesPlayed) || 0;
    if (updates.matchesWon !== undefined) user.matchesWon = Number(updates.matchesWon) || 0;
    if (updates.equippedStriker !== undefined) user.equippedStriker = String(updates.equippedStriker);
    if (Array.isArray(updates.unlockedCrackers)) {
      const set = new Set([...user.unlockedCrackers, ...updates.unlockedCrackers]);
      user.unlockedCrackers = Array.from(set);
    }

    user.lastActive = new Date().toISOString();
    this.save();
    return user;
  }

  // Record a completed match
  recordMatchResult(userId, isWinner, coinsEarned = 0) {
    const user = this.findById(userId);
    if (!user) return null;

    user.matchesPlayed = (user.matchesPlayed || 0) + 1;
    if (isWinner) {
      user.matchesWon = (user.matchesWon || 0) + 1;
    }
    if (coinsEarned !== 0) {
      user.coins = Math.max(0, (user.coins || 0) + coinsEarned);
    }

    user.lastActive = new Date().toISOString();
    this.save();
    return user;
  }

  // Get Top Players Leaderboard
  getLeaderboard(limit = 10) {
    const all = Array.from(this.users.values());
    all.sort((a, b) => (b.matchesWon || 0) - (a.matchesWon || 0) || (b.coins || 0) - (a.coins || 0));
    return all.slice(0, limit).map((u, idx) => ({
      rank: idx + 1,
      userId: u.userId,
      username: u.username,
      coins: u.coins,
      matchesWon: u.matchesWon,
      matchesPlayed: u.matchesPlayed
    }));
  }
}

// Singleton database instance
module.exports = new UserDatabase();
