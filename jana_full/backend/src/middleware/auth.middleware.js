function authMiddleware(req, res, next) {
  const header = req.headers.authorization;

  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing Authorization header' });
  }

  const token = header.split(' ')[1];

  try {
    // JWT payload is the middle part, base64 encoded
    // We decode it without verifying the signature
    const parts   = token.split('.');
    if (parts.length !== 3) {
      return res.status(401).json({ error: 'Malformed token' });
    }

    // base64url decode the payload section
    const payload = JSON.parse(
      Buffer.from(parts[1], 'base64url').toString('utf8')
    );

    // check the token hasn't expired — this we can do without the secret
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp && payload.exp < now) {
      return res.status(401).json({ error: 'Token expired' });
    }

    if (!payload.sub) {
      return res.status(401).json({ error: 'Invalid token: no user id' });
    }

    req.user = {
      id:    payload.sub,
      email: payload.email ?? null,
      role:  payload.role  ?? null,
    };

    next();
  } catch (err) {
    console.error('[auth] token decode error:', err.message);
    return res.status(401).json({ error: 'Invalid token' });
  }
}

module.exports = authMiddleware;