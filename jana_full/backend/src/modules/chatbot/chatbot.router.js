const express = require('express');
const { getOrCreateSession, getHistory, handleMessage } = require('./chatbot.service');
const { getSummary } = require('../biomarkers/biomarkers.service');

const router = express.Router();

// GET /api/chatbot/session
// Called when the chat screen opens - get or create a session
router.get('/session', async (req, res, next) => {
  try {
    const session = await getOrCreateSession(req.user.id);
    res.json({ session });
  } catch (err) {
    next(err);
  }
});

// GET /api/chatbot/history?session_id=xxx
router.get('/history', async (req, res, next) => {
  try {
    const { session_id } = req.query;
    if (!session_id) return res.status(400).json({ error: 'session_id required' });

    const messages = await getHistory(session_id);
    res.json({ messages });
  } catch (err) {
    next(err);
  }
});

// POST /api/chatbot/message
// Main endpoint - receives user message, returns Medi's reply
router.post('/message', async (req, res, next) => {
  try {
    const { session_id, message } = req.body;
    if (!session_id || !message) {
      return res.status(400).json({ error: 'session_id and message are required' });
    }

    // fetch user's latest biomarker data to give Medi context
    const summary = await getSummary(req.user.id);
    const result  = await handleMessage(req.user.id, session_id, message, summary);

    res.json(result);
  } catch (err) {
    next(err);
  }
});

module.exports = router;
