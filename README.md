# QuickSlot

A sports-slot booking app that lets users find venues, book hourly slots, and manage their reservations — with real-time availability and guaranteed no double-booking.

---

## Features

- **Browse venues** — badminton courts and football pitches with location info
- **Slot grid** — hourly slots from 06:00–22:00, available vs booked at a glance
- **Instant booking** — tap a slot, confirm, done; 409 conflicts handled gracefully
- **Live availability** — slot grid polls every 5 seconds, no refresh needed
- **My Bookings** — view and cancel your upcoming bookings
- **Auth** — email/password login and registration with JWT, session persisted securely
- **No double-booking** — enforced at the database level via a UNIQUE constraint + atomic INSERT

---

## Tech Stack

| Layer     | Tech                                             |
|-----------|--------------------------------------------------|
| Frontend  | Flutter (Dart), Provider, Dio                    |
| Auth storage | flutter_secure_storage (iOS Keychain)         |
| Backend   | Node.js, Express                                 |
| Database  | SQLite (better-sqlite3) with WAL mode            |
| Auth      | JWT (jsonwebtoken) + bcrypt (bcryptjs)           |
| Hosting   | Railway                                          |

---

## Project Structure

```
quickslot/
├── app/          # Flutter frontend
│   └── lib/
│       ├── models/       # Venue, Slot, Booking, ViewState
│       ├── providers/    # AuthProvider, VenuesProvider, SlotsProvider, BookingsProvider
│       ├── screens/      # LoginScreen, VenuesScreen, SlotsScreen, MyBookingsScreen
│       ├── services/     # ApiClient (Dio)
│       └── widgets/      # VenueCard, SlotTile, BookingCard
└── server/       # Node/Express backend
    ├── index.js  # All API routes
    ├── db.js     # SQLite setup + seeding
    └── auth.js   # JWT middleware
```

---

## API Endpoints

| Method | Path                      | Auth | Description                  |
|--------|---------------------------|------|------------------------------|
| POST   | /auth/register            | —    | Create account, returns JWT  |
| POST   | /auth/login               | —    | Login, returns JWT           |
| GET    | /venues                   | —    | List all venues              |
| GET    | /venues/:id/slots         | —    | Hourly slots with availability |
| POST   | /bookings                 | JWT  | Book a slot (409 if taken)   |
| GET    | /users/:id/bookings       | JWT  | List user's bookings         |
| DELETE | /bookings/:id             | JWT  | Cancel a booking             |

---

## Running Locally

### Backend

```bash
cd server
npm install
node index.js        # starts on port 3000
```

Seeded test accounts (password: `password123`):
- `alice@quickslot.com`
- `bob@quickslot.com`
- `carol@quickslot.com`

### Frontend

```bash
cd app
flutter pub get
flutter run
```

Requires Flutter 3.x and a connected device or simulator.

---

## Concurrency Design

Double-booking is prevented purely at the database layer:

```sql
UNIQUE(venue_id, slot_datetime)
```

The server performs a single atomic `INSERT` — no read-before-write. A conflict throws `SQLITE_CONSTRAINT_UNIQUE`, which maps to a `409 Conflict` response. The Flutter client catches this and shows a graceful "slot just taken" message before refreshing the grid.

---

## Live Backend

`https://quickslot-production.up.railway.app`
