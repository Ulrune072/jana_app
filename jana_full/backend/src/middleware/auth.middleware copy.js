const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.SUPABASE_JWT_SECRET;

if (!JWT_SECRET) {
  console.error('[auth] SUPABASE_JWT_SECRET not set in .env — see Supabase dashboard → Project Settings → API → JWT Secret');
  process.exit(1);
}

function authMiddleware(req, res, next) {
  const header = req.headers.authorization;

  if (!header || !header.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing Authorization header' });
  }

  const token = header.split(' ')[1];

  try {
    // verify signature and expiry locally — zero network calls
    const decoded = jwt.verify(token, JWT_SECRET);

    // Supabase puts the user's UUID in the 'sub' field of the token
    // and the role in 'role'. We attach a minimal user object so the
    // rest of the code doesn't need to change — req.user.id still works.
    req.user = {
      id:    decoded.sub,
      email: decoded.email,
      role:  decoded.role,
    };

    next();
  } catch (err) {
    // jwt.verify throws if the token is expired or the signature is wrong
    if (err.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired — please log in again' });
    }
    return res.status(401).json({ error: 'Invalid token' });
  }
}

module.exports = authMiddleware;