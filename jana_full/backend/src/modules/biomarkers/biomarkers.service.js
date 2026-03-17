const supabase   = require('../../config/supabase');
const THRESHOLDS = require('./biomarkers.thresholds');
const alertsService = require('../alerts/alerts.service');

// valid enum values - used for validation before hitting the DB
const VALID_TYPES = [
  'heart_rate', 'blood_pressure_sys', 'blood_pressure_dia',
  'blood_glucose', 'oxygen_saturation', 'steps',
];
const VALID_SOURCES = ['manual', 'bluetooth', 'simulated'];

// ─── ingest ──────────────────────────────────────────────────────────────────
// Accepts an array of readings, validates each one, saves them,
// then checks thresholds for each one individually.
async function ingestReadings(userId, readings) {
  // validate each reading before touching the DB
  for (const r of readings) {
    if (!VALID_TYPES.includes(r.type)) {
      throw Object.assign(new Error(`Invalid biomarker type: ${r.type}`), { status: 400 });
    }
    if (typeof r.value !== 'number' || r.value < 0) {
      throw Object.assign(new Error(`Invalid value for ${r.type}: ${r.value}`), { status: 400 });
    }
    if (r.source && !VALID_SOURCES.includes(r.source)) {
      throw Object.assign(new Error(`Invalid source: ${r.source}`), { status: 400 });
    }
  }

  // build rows to insert
  const rows = readings.map(r => ({
    user_id:     userId,
    type:        r.type,
    value:       r.value,
    source:      r.source || 'manual',
    device_name: r.device_name || null,
    recorded_at: r.recorded_at || new Date().toISOString(),
  }));

  const { data, error } = await supabase
    .from('biomarker_readings')
    .insert(rows)
    .select();

  if (error) throw new Error(error.message);

  // check thresholds for every inserted reading - fire and forget alerts
  // we don't await this so the API responds fast and alerts happen in background
  for (const reading of data) {
    checkThresholdsAndAlert(userId, reading).catch(err =>
      console.error('[threshold check error]', err.message)
    );
  }

  return data;
}

// ─── threshold check ─────────────────────────────────────────────────────────
async function checkThresholdsAndAlert(userId, reading) {
  const limits = THRESHOLDS[reading.type];
  if (!limits) return; // steps - no threshold

  const v = Number(reading.value);
  let severity = null;

  if (v < limits.critical.low || v > limits.critical.high) {
    severity = 'critical';
  } else if (v < limits.warning.low || v > limits.warning.high) {
    severity = 'warning';
  }

  if (!severity) return; // reading is fine

  const direction = v < limits.warning.low ? 'below' : 'above';
  const limit     = v < limits.warning.low
    ? limits[severity].low
    : limits[severity].high;

  const message = `${formatType(reading.type)} ${v} ${limits.unit} — ${direction} ${severity} limit (${limit} ${limits.unit})`;

  await alertsService.createAlert(userId, reading.id, reading.type, severity, message);
}

// ─── latest ──────────────────────────────────────────────────────────────────
// Returns the single most recent reading for each biomarker type.
// Used by the dashboard summary cards.
async function getLatestReadings(userId) {
  // We query once per type and grab the most recent row.
  // Not the most elegant SQL but it's simple and fast enough for MVP.
  const results = {};

  for (const type of VALID_TYPES) {
    const { data } = await supabase
      .from('biomarker_readings')
      .select('*')
      .eq('user_id', userId)
      .eq('type', type)
      .order('recorded_at', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (data) results[type] = data;
  }

  return results;
}

// ─── history ─────────────────────────────────────────────────────────────────
// Returns readings for a specific type filtered by time range.
// Used by the blood pressure chart.
async function getHistory(userId, type, range) {
  if (!VALID_TYPES.includes(type)) {
    throw Object.assign(new Error(`Invalid type: ${type}`), { status: 400 });
  }

  const now  = new Date();
  const from = new Date(now);

  if (range === 'day')   from.setDate(now.getDate() - 1);
  else if (range === 'week')  from.setDate(now.getDate() - 7);
  else if (range === 'month') from.setMonth(now.getMonth() - 1);
  else from.setDate(now.getDate() - 7); // default to week

  const { data, error } = await supabase
    .from('biomarker_readings')
    .select('id, value, recorded_at, source')
    .eq('user_id', userId)
    .eq('type', type)
    .gte('recorded_at', from.toISOString())
    .order('recorded_at', { ascending: true });

  if (error) throw new Error(error.message);
  return data;
}

// ─── summary ─────────────────────────────────────────────────────────────────
// Returns a flat object used by the chatbot and dashboard.
// Easier for Medi to reference than the nested latest readings object.
async function getSummary(userId) {
  const latest = await getLatestReadings(userId);
  return {
    heart_rate:        latest.heart_rate?.value        ?? null,
    blood_pressure_sys: latest.blood_pressure_sys?.value ?? null,
    blood_pressure_dia: latest.blood_pressure_dia?.value ?? null,
    blood_glucose:     latest.blood_glucose?.value     ?? null,
    oxygen_saturation: latest.oxygen_saturation?.value ?? null,
    steps:             latest.steps?.value             ?? null,
    last_updated:      new Date().toISOString(),
  };
}

// helper - turns 'heart_rate' into 'Heart rate' for messages
function formatType(type) {
  return type.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

module.exports = { ingestReadings, getLatestReadings, getHistory, getSummary };
