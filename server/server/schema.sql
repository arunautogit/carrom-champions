-- =============================================================================
-- CARROM CHAMPIONS - SQL DATABASE SCHEMA (PostgreSQL / Cloud SQL / SQLite)
-- =============================================================================

CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(32) PRIMARY KEY,
    username VARCHAR(32) UNIQUE NOT NULL,
    device_id VARCHAR(64),
    coins INTEGER DEFAULT 1000,
    matches_played INTEGER DEFAULT 0,
    matches_won INTEGER DEFAULT 0,
    unlocked_crackers JSONB DEFAULT '["classic_sparkler"]'::jsonb,
    equipped_striker VARCHAR(32) DEFAULT 'default',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_active TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_users_username ON users(LOWER(username));
CREATE INDEX IF NOT EXISTS idx_users_coins ON users(coins DESC);
CREATE INDEX IF NOT EXISTS idx_users_wins ON users(matches_won DESC);

CREATE TABLE IF NOT EXISTS match_history (
    match_id VARCHAR(32) PRIMARY KEY,
    room_code VARCHAR(8) NOT NULL,
    player_count INTEGER NOT NULL,
    variant VARCHAR(32) DEFAULT 'normal',
    winner_user_id VARCHAR(32) REFERENCES users(user_id),
    duration_seconds INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
