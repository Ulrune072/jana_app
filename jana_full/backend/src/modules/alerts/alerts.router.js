const express = require('express');
const { getAlerts, getUnreadCount } = require('./alerts.service');

const router = express.Router();

// GET /api/alerts
router.get('/', async (req, res, next) => {
  try {
    const data  = await getAlerts(req.user.id);
    const unread = await getUnreadCount(req.user.id);
    res.json({ data, unread });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
