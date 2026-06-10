const jwt = require('jsonwebtoken');

// Fallback is fine for local dev; set JWT_SECRET in the Railway env panel for prod.
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-prod';

function requireAuth(req, res, next) {
  const header = req.headers.authorization ?? '';
  if (!header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'authorization header required' });
  }
  try {
    // jwt.verify throws on expiry, bad signature, malformed token — all caught below.
    const payload = jwt.verify(header.slice(7), JWT_SECRET);
    req.userId = payload.sub; // integer user id stored in the 'sub' claim
    next();
  } catch {
    res.status(401).json({ error: 'invalid or expired token' });
  }
}

module.exports = { requireAuth, JWT_SECRET };
