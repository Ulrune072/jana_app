const express = require('express');
const { ingestReadings, getLatestReadings, getHistory, getSummary } = require('./biomarkers.service');

const router = express.Router();

// POST /api/biomarkers/ingest
// Accepts array of readings from simulator, manual input, or BLE.
// All three data sources call this same endpoint.
router.post('/ingest', async (req, res, next) => {
  try {
    // body can be a single object or an array - normalise to array
    const readings = Array.isArray(req.body) ? req.body : [req.body];

    if (readings.length === 0) {
      return res.status(400).json({ error: 'No readings provided' });
    }

    const inserted = await ingestReadings(req.user.id, readings);
    res.status(201).json({ inserted: inserted.length, data: inserted });
  } catch (err) {
    next(err);
  }
});

// GET /api/biomarkers/latest
// Dashboard calls this on load to populate all cards
router.get('/latest', async (req, res, next) => {
  try {
    const data = await getLatestReadings(req.user.id);
    res.json({ data });
  } catch (err) {
    next(err);
  }
});

// GET /api/biomarkers/summary
// Chatbot calls this to get flat numbers to inject into AI prompt
router.get('/summary', async (req, res, next) => {
  try {
    const data = await getSummary(req.user.id);
    res.json({ data });
  } catch (err) {
    next(err);
  }
});

// GET /api/biomarkers/:type/history?range=day|week|month
// Blood pressure chart calls this with type=blood_pressure_sys or _dia
router.get('/:type/history', async (req, res, next) => {
  try {
    const { type } = req.params;
    const range = req.query.range || 'week';
    const data  = await getHistory(req.user.id, type, range);
    // At the very end, just before res.json(...)
    console.log('[DEBUG] biomarker history response:',
      JSON.stringify(data.map(r => ({
        id:          r.id,
        id_type:     typeof r.id,
        source:      r.source,
        source_type: typeof r.source,
        value:       r.value,
        recorded_at: r.recorded_at,
      })), null, 2)
    );

    res.json({ data });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
