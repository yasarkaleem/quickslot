const Database = require('better-sqlite3');
const path = require('path');

// On Railway with a persistent volume mounted at /data, set DB_PATH=/data/quickslot.db.
// Falls back to a local file for dev.
const DB_PATH = process.env.DB_PATH || path.join(__dirname, 'quickslot.db');
const db = new Database(DB_PATH);

// WAL lets readers and the writer run concurrently without blocking each other
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    email         TEXT NOT NULL UNIQUE,
    password_hash TEXT NOT NULL,
    created_at    TEXT NOT NULL DEFAULT (datetime('now'))
  );

  CREATE TABLE IF NOT EXISTS venues (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    name     TEXT NOT NULL,
    sport    TEXT NOT NULL,
    location TEXT NOT NULL
  );

  CREATE TABLE IF NOT EXISTS bookings (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    venue_id      INTEGER NOT NULL REFERENCES venues(id),
    slot_datetime TEXT NOT NULL,
    user_id       INTEGER NOT NULL REFERENCES users(id),
    created_at    TEXT NOT NULL DEFAULT (datetime('now')),
    UNIQUE(venue_id, slot_datetime)
  );
`);

// Seed users once. bcrypt.hashSync is synchronous; 10 rounds ≈ 100 ms each — fine at startup.
const userCount = db.prepare('SELECT COUNT(*) AS n FROM users').get().n;
if (userCount === 0) {
  const bcrypt = require('bcryptjs');
  const insUser = db.prepare('INSERT INTO users (email, password_hash) VALUES (?, ?)');
  const h = (pw) => bcrypt.hashSync(pw, 10);
  insUser.run('alice@quickslot.com', h('password123'));
  insUser.run('bob@quickslot.com',   h('password123'));
  insUser.run('carol@quickslot.com', h('password123'));
}

const venueCount = db.prepare('SELECT COUNT(*) AS n FROM venues').get().n;
if (venueCount === 0) {
  const ins = db.prepare('INSERT INTO venues (name, sport, location) VALUES (?, ?, ?)');
  ins.run('Smash Arena',  'badminton', 'Downtown');
  ins.run('Court Side',   'badminton', 'Westside');
  ins.run('Green Turf',   'football',  'Northpark');
  ins.run('The Pitch',    'football',  'Eastend');
}

module.exports = db;
