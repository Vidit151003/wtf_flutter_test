const express = require('express');
const cors = require('cors');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
app.use(cors({ origin: '*' }));
app.use(express.json());

const HMS_ACCESS_KEY = process.env.HMS_ACCESS_KEY;
const HMS_SECRET = process.env.HMS_SECRET;
const PORT = process.env.PORT || 3000;
const DEV_FALLBACK_ROOM_ID = process.env.DEV_FALLBACK_ROOM_ID || 'dev-room-001';

// GET /token — Generate 100ms management token
app.get('/token', (req, res) => {
  const { userId, role } = req.query;

  if (!userId || !role) {
    return res.status(400).json({ error: 'Missing required params: userId, role' });
  }

  if (!HMS_ACCESS_KEY || !HMS_SECRET) {
    console.warn('[RTC] HMS credentials not configured. Set HMS_ACCESS_KEY and HMS_SECRET in .env');
    // Return a dev stub token when credentials are missing
    return res.status(200).json({
      token: 'dev-stub-token',
      roomId: DEV_FALLBACK_ROOM_ID,
      warning: '100ms credentials not configured — using dev stub',
    });
  }

  try {
    const payload = {
      access_key: HMS_ACCESS_KEY,
      type: 'management',
      version: 2,
      iat: Math.floor(Date.now() / 1000),
      exp: Math.floor(Date.now() / 1000) + 86400, // 24h
      jti: `${userId}-${Date.now()}`,
    };

    const token = jwt.sign(payload, HMS_SECRET, { algorithm: 'HS256' });

    console.log(`[RTC] Token generated for userId=${userId} role=${role}`);
    res.json({ token, roomId: DEV_FALLBACK_ROOM_ID });
  } catch (err) {
    console.error('[RTC] Token signing failed:', err.message);
    res.status(500).json({ error: "Couldn't connect to call. Tap to retry." });
  }
});

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.listen(PORT, () => {
  console.log(`[SERVER] Token server running on http://localhost:${PORT}`);
});
