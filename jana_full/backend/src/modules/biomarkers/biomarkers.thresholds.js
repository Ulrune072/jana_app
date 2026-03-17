// Medical reference ranges used for threshold checking.
// warning range = outside normal but not immediately dangerous
// critical range = needs attention right now
//
// These are based on standard clinical reference values.
// Stored separately so the team can tweak numbers without
// touching any service logic.

const THRESHOLDS = {
  heart_rate: {
    warning:  { low: 50,  high: 100 },
    critical: { low: 40,  high: 130 },
    unit: 'bpm',
  },
  blood_pressure_sys: {
    warning:  { low: 90,  high: 139 },
    critical: { low: 80,  high: 180 },
    unit: 'mmHg',
  },
  blood_pressure_dia: {
    warning:  { low: 60,  high: 89 },
    critical: { low: 50,  high: 120 },
    unit: 'mmHg',
  },
  blood_glucose: {
    warning:  { low: 3.9, high: 7.8 },
    critical: { low: 3.0, high: 11.0 },
    unit: 'mmol/L',
  },
  oxygen_saturation: {
    warning:  { low: 95,  high: 100 },
    critical: { low: 90,  high: 100 },
    unit: '%',
  },
  // steps has no medical threshold - we just store it
};

module.exports = THRESHOLDS;
