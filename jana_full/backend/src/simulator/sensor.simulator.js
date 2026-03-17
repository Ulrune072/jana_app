// sensor.simulator.js
// Run with: npm run simulate
// Sends realistic biomarker readings every 10 seconds to the local backend.
// Occasionally dips into warning territory so the alert system gets triggered
// during demos.
//
// Setup before running:
//   1. Start the backend first: npm run dev
//   2. Log in to the app once and grab the JWT from the debug output
//      (temporarily add console.log(session.access_token) in auth_provider.dart)
//   3. Paste it as SIMULATOR_TEST_TOKEN in your .env
//   4. Paste your user UUID as SIMULATOR_USER_ID in your .env

require('dotenv').config({ path: require('path').join(__dirname, '../../.env') });

const API_URL = `http://localhost:${process.env.PORT || 3000}`;
const TOKEN   = process.env.SIMULATOR_TEST_TOKEN;

if (!TOKEN) {
  console.error('SIMULATOR_TEST_TOKEN not set in .env — see instructions at top of this file');
  process.exit(1);
}

let tick = 0; // used to trigger occasional warning readings every ~5 ticks

function rand(min, max, decimals = 1) {
  const val = min + Math.random() * (max - min);
  return parseFloat(val.toFixed(decimals));
}

function generateReadings() {
  tick++;
  const isSpike = tick % 7 === 0; // every 7th tick generates slightly abnormal values

  return [
    {
      type:   'heart_rate',
      value:  isSpike ? rand(101, 115) : rand(62, 95),
      source: 'simulated',
    },
    {
      type:   'blood_pressure_sys',
      value:  isSpike ? rand(140, 160) : rand(105, 135),
      source: 'simulated',
    },
    {
      type:   'blood_pressure_dia',
      value:  isSpike ? rand(90, 100) : rand(65, 85),
      source: 'simulated',
    },
    {
      type:   'oxygen_saturation',
      value:  isSpike ? rand(92, 94) : rand(96, 100),
      source: 'simulated',
    },
    {
      type:   'blood_glucose',
      value:  rand(4.2, 6.5),
      source: 'simulated',
    },
    {
      type:   'steps',
      value:  Math.floor(rand(50, 300, 0)), // steps per interval
      source: 'simulated',
    },
  ];
}

async function sendReadings() {
  const readings = generateReadings();
  try {
    const res = await fetch(`${API_URL}/api/biomarkers/ingest`, {
      method:  'POST',
      headers: {
        'Content-Type':  'application/json',
        'Authorization': `Bearer ${TOKEN}`,
      },
      body: JSON.stringify(readings),
    });

    const json = await res.json();
    if (res.ok) {
      const spikeNote = tick % 7 === 0 ? ' ⚠️  (spike tick)' : '';
      console.log(`[${new Date().toLocaleTimeString()}] Sent ${json.inserted} readings${spikeNote}`);
    } else {
      console.error('[simulator] API error:', json.error);
      if (res.status === 401) {
        console.error('Token expired - get a fresh JWT from the app and update .env');
      }
    }
  } catch (err) {
    console.error('[simulator] network error:', err.message);
    console.error('Is the backend running? Try: npm run dev');
  }
}

console.log('JANA sensor simulator started');
console.log(`Sending readings to ${API_URL} every 10 seconds`);
console.log('Every 7th tick generates slightly abnormal values to trigger alerts');
console.log('Press Ctrl+C to stop\n');

// send once immediately so you don't wait 10 seconds to see the first reading
sendReadings();
setInterval(sendReadings, 10_000);
