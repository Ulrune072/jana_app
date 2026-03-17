// Rule-based responses for Medi.
// These handle the numbered menu from the Figma prototype (options 1-7)
// plus natural language variants of the same questions.
//
// If a message matches a rule, we return immediately without calling Gemini.
// This keeps costs at zero for the most common interactions.

const RULES = [
  {
    pattern: /\b(1|heart.?rate|pulse|bpm)\b/i,
    reply: (s) => s.heart_rate != null
      ? `Your latest heart rate is **${s.heart_rate} bpm**.${rateComment(s.heart_rate)}`
      : "I don't have a heart rate reading for you yet. Try adding one manually.",
  },
  {
    pattern: /\b(2|blood.?pressure|bp|systolic|diastolic)\b/i,
    reply: (s) => s.blood_pressure_sys != null
      ? `Your latest blood pressure is **${s.blood_pressure_sys}/${s.blood_pressure_dia} mmHg**.${bpComment(s.blood_pressure_sys)}`
      : "No blood pressure reading on file yet.",
  },
  {
    pattern: /\b(3|glucose|blood.?sugar|sugar)\b/i,
    reply: (s) => s.blood_glucose != null
      ? `Your blood glucose is **${s.blood_glucose} mmol/L**.${glucoseComment(s.blood_glucose)}`
      : "No glucose reading on file yet.",
  },
  {
    pattern: /\b(4|oxygen|spo2|saturation|o2)\b/i,
    reply: (s) => s.oxygen_saturation != null
      ? `Oxygen saturation is **${s.oxygen_saturation}%**.${spo2Comment(s.oxygen_saturation)}`
      : "No oxygen saturation reading on file yet.",
  },
  {
    pattern: /\b(5|summary|overview|how am i|all readings|all data|my stats)\b/i,
    reply: (s) => buildSummary(s),
  },
  {
    pattern: /\b(6|help|options|menu|what can you do|commands)\b/i,
    reply: () =>
      "Here's what I can help with:\n" +
      "1 - Heart rate\n2 - Blood pressure\n3 - Blood glucose\n" +
      "4 - Oxygen saturation\n5 - Full summary\n6 - Help\n7 - Health tips\n\n" +
      "Or just ask me anything health-related!",
  },
  {
    pattern: /\b(7|tip|tips|advice|recommend|suggestion)\b/i,
    reply: () => randomTip(),
  },
];

function matchRule(message, summary) {
  for (const rule of RULES) {
    if (rule.pattern.test(message)) {
      return rule.reply(summary);
    }
  }
  return null; // no match - hand off to Gemini
}

// ─── helpers ─────────────────────────────────────────────────────────────────

function rateComment(hr) {
  if (hr > 100) return ' That is slightly elevated. Try to relax and breathe slowly.';
  if (hr < 50)  return ' That is quite low. If you feel dizzy, please consult your doctor.';
  return ' That looks normal.';
}

function bpComment(sys) {
  if (sys > 139) return ' That is above the normal range. Consider reducing salt intake and stress.';
  if (sys < 90)  return ' That is on the low side. Stay hydrated.';
  return ' That is in a healthy range.';
}

function glucoseComment(g) {
  if (g > 7.8)  return ' That is above normal. Try to reduce sugary foods.';
  if (g < 3.9)  return ' That is below normal. Consider having a small snack.';
  return ' That is within normal range.';
}

function spo2Comment(o2) {
  if (o2 < 95) return ' That is lower than normal. If you are feeling short of breath, seek medical advice.';
  return ' That is normal.';
}

function buildSummary(s) {
  const lines = ['Here is your current health summary:\n'];
  if (s.heart_rate != null)        lines.push(`❤️ Heart rate: **${s.heart_rate} bpm**`);
  if (s.blood_pressure_sys != null) lines.push(`🩸 Blood pressure: **${s.blood_pressure_sys}/${s.blood_pressure_dia} mmHg**`);
  if (s.blood_glucose != null)     lines.push(`💉 Blood glucose: **${s.blood_glucose} mmol/L**`);
  if (s.oxygen_saturation != null) lines.push(`🫁 Oxygen saturation: **${s.oxygen_saturation}%**`);
  if (s.steps != null)             lines.push(`👟 Steps today: **${s.steps}**`);
  if (lines.length === 1) return "No readings found yet. Add some data first!";
  return lines.join('\n');
}

const TIPS = [
  'Try to get at least 30 minutes of moderate exercise today — even a brisk walk counts.',
  'Drink water regularly. Most adults need around 2 litres per day.',
  'If your blood pressure has been high, reducing salt and stress can help significantly.',
  'A consistent sleep schedule (7-9 hours) has a direct positive effect on heart rate and glucose.',
  'Deep breathing for 5 minutes can lower your heart rate noticeably. Give it a try.',
  'Avoid checking your phone for the first 30 minutes after waking — it reduces morning cortisol spikes.',
];

function randomTip() {
  return '💡 ' + TIPS[Math.floor(Math.random() * TIPS.length)];
}

module.exports = { matchRule };
