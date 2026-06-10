const express = require('express');
const bcrypt  = require('bcryptjs');
const jwt     = require('jsonwebtoken');
const db      = require('./db');
const { requireAuth, JWT_SECRET } = require('./auth');

const app = express();
app.use(express.json());

// ── Auth ──────────────────────────────────────────────────────────────────────

app.post('/auth/register', (req, res) => {
  const { email, password } = req.body;
  if (!email || !password)          return res.status(400).json({ error: 'email and password required' });
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email))
                                    return res.status(400).json({ error: 'invalid email' });
  if (password.length < 6)          return res.status(400).json({ error: 'password min 6 chars' });

  try {
    const result = db
      .prepare('INSERT INTO users (email, password_hash) VALUES (?, ?)')
      .run(email.toLowerCase(), bcrypt.hashSync(password, 10));

    const token = jwt.sign({ sub: result.lastInsertRowid, email }, JWT_SECRET, { expiresIn: '7d' });
    res.status(201).json({ token, userId: result.lastInsertRowid });
  } catch (err) {
    if (err.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({ error: 'email already registered' });
    }
    throw err;
  }
});

app.post('/auth/login', (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'email and password required' });

  const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email.toLowerCase());

  // Compare even when user is missing to avoid timing-based user enumeration.
  const hashToCheck = user?.password_hash ?? '$2b$10$invalidhashpaddingtomakeconstanttime';
  const valid = bcrypt.compareSync(password, hashToCheck);

  if (!user || !valid) return res.status(401).json({ error: 'invalid email or password' });

  const token = jwt.sign({ sub: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
  res.json({ token, userId: user.id });
});

// ── Venues ────────────────────────────────────────────────────────────────────

app.get('/venues', (req, res) => {
  res.json(db.prepare('SELECT * FROM venues').all());
});

// ── Slots ─────────────────────────────────────────────────────────────────────

app.get('/venues/:id/slots', (req, res) => {
  const { id } = req.params;
  const { date } = req.query;

  if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return res.status(400).json({ error: 'date query param required (YYYY-MM-DD)' });
  }

  const venue = db.prepare('SELECT id FROM venues WHERE id = ?').get(id);
  if (!venue) return res.status(404).json({ error: 'venue not found' });

  const booked = new Set(
    db.prepare("SELECT slot_datetime FROM bookings WHERE venue_id = ? AND slot_datetime LIKE ?")
      .all(id, `${date}T%`)
      .map(r => r.slot_datetime)
  );

  const slots = [];
  for (let h = 6; h <= 22; h++) {
    const slot_datetime = `${date}T${String(h).padStart(2, '0')}:00:00`;
    slots.push({ slot_datetime, status: booked.has(slot_datetime) ? 'booked' : 'available' });
  }
  res.json(slots);
});

// ── Bookings ──────────────────────────────────────────────────────────────────

app.post('/bookings', requireAuth, (req, res) => {
  const { venue_id, slot_datetime } = req.body;

  if (!venue_id || !slot_datetime) {
    return res.status(400).json({ error: 'venue_id and slot_datetime required' });
  }

  const venue = db.prepare('SELECT id FROM venues WHERE id = ?').get(venue_id);
  if (!venue) return res.status(400).json({ error: 'venue not found' });

  const match = slot_datetime.match(/^(\d{4}-\d{2}-\d{2})T(\d{2}):00:00$/);
  if (!match) return res.status(400).json({ error: 'slot_datetime must be YYYY-MM-DDTHH:00:00' });

  const hour = parseInt(match[2], 10);
  if (hour < 6 || hour > 22) return res.status(400).json({ error: 'slot hour must be 06–22' });

  try {
    const result = db
      .prepare('INSERT INTO bookings (venue_id, slot_datetime, user_id) VALUES (?, ?, ?)')
      .run(venue_id, slot_datetime, req.userId);

    res.status(201).json({ id: result.lastInsertRowid, venue_id, slot_datetime, user_id: req.userId });
  } catch (err) {
    if (err.code === 'SQLITE_CONSTRAINT_UNIQUE') {
      return res.status(409).json({ error: 'slot_taken' });
    }
    throw err;
  }
});

app.get('/users/:id/bookings', requireAuth, (req, res) => {
  // Users may only fetch their own bookings.
  if (String(req.userId) !== req.params.id) {
    return res.status(403).json({ error: 'forbidden' });
  }

  const bookings = db.prepare(`
    SELECT b.id, b.venue_id, v.name AS venue_name, v.sport,
           b.slot_datetime, b.user_id, b.created_at
    FROM bookings b
    JOIN venues v ON b.venue_id = v.id
    WHERE b.user_id = ?
    ORDER BY b.slot_datetime
  `).all(req.userId);

  res.json(bookings);
});

app.delete('/bookings/:id', requireAuth, (req, res) => {
  const booking = db.prepare('SELECT user_id FROM bookings WHERE id = ?').get(req.params.id);
  if (!booking) return res.status(404).json({ error: 'booking not found' });

  // Prevent a user from cancelling someone else's booking.
  if (booking.user_id !== req.userId) return res.status(403).json({ error: 'forbidden' });

  db.prepare('DELETE FROM bookings WHERE id = ?').run(req.params.id);
  res.json({ deleted: true });
});

// ── Start ─────────────────────────────────────────────────────────────────────

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`QuickSlot listening on :${PORT}`));
