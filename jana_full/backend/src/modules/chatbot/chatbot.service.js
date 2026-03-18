const supabase  = require('../../config/supabase');
const { matchRule } = require('./chatbot.rules');
const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY, {
  apiVersion: 'v1beta',
});

// ─── getOrCreateSession ───────────────────────────────────────────────────────
// Each user has one active session at a time for the MVP.
// We just grab the most recent one, or create a new one if none exists.
async function getOrCreateSession(userId) {
  const { data: existing } = await supabase
    .from('chat_sessions')
    .select('id, started_at')
    .eq('user_id', userId)
    .order('started_at', { ascending: false })
    .limit(1)
    .maybeSingle();

  if (existing) return existing;

  const { data: created, error } = await supabase
    .from('chat_sessions')
    .insert({ user_id: userId })
    .select()
    .single();

  if (error) throw new Error(error.message);
  return created;
}

// ─── getHistory ───────────────────────────────────────────────────────────────
async function getHistory(sessionId, limit = 20) {
  const { data, error } = await supabase
    .from('chat_messages')
    .select('role, content, sent_at')
    .eq('session_id', sessionId)
    .order('sent_at', { ascending: true })
    .limit(limit);

  if (error) throw new Error(error.message);
  return data;
}

// ─── saveMessage ─────────────────────────────────────────────────────────────
async function saveMessage(sessionId, role, content) {
  const { error } = await supabase
    .from('chat_messages')
    .insert({ session_id: sessionId, role, content });

  if (error) console.error('[chatbot] save message error:', error.message);
}

// ─── handleMessage ────────────────────────────────────────────────────────────
async function handleMessage(userId, sessionId, userMessage, summary) {
  // always save the user's message first
  await saveMessage(sessionId, 'user', userMessage);

  // try rule-based response first
  const ruleReply = matchRule(userMessage, summary);

  if (ruleReply) {
    await saveMessage(sessionId, 'assistant', ruleReply);
    return { reply: ruleReply, source: 'rules' };
  }

  // no rule matched - call Gemini
  const aiReply = await callGemini(userId, sessionId, userMessage, summary);
  await saveMessage(sessionId, 'assistant', aiReply);
  return { reply: aiReply, source: 'ai' };
}

// ─── callGemini ───────────────────────────────────────────────────────────────
async function callGemini(userId, sessionId, userMessage, summary) {
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash-lite' });

    // load last 10 messages for context
    const history = await getHistory(sessionId, 10);

    // Build the system context.
    // Injecting the user's actual health data is what makes Medi
    // give personalised answers instead of generic health advice.
    const systemContext = `You are Medi, a friendly health assistant inside the JANA app.
You help patients understand their health data. Be concise and caring.
Only answer health-related questions. If asked about something unrelated to health, 
politely redirect to health topics.

The patient's current readings are:
- Heart rate: ${summary.heart_rate ?? 'no data'} bpm
- Blood pressure: ${summary.blood_pressure_sys ?? 'no data'}/${summary.blood_pressure_dia ?? 'no data'} mmHg
- Blood glucose: ${summary.blood_glucose ?? 'no data'} mmol/L
- Oxygen saturation: ${summary.oxygen_saturation ?? 'no data'}%
- Steps today: ${summary.steps ?? 'no data'}

Keep responses short (2-3 sentences max). Do not recommend specific medications.`;

    // Gemini uses a chat history format
    const chat = model.startChat({
      history: history.slice(0, -1).map(m => ({
        role: m.role === 'assistant' ? 'model' : 'user',
        parts: [{ text: m.content }],
      })),
      systemInstruction: {
        role: 'system',
        parts: [{ text: systemContext }],
      },
    });

    const result = await chat.sendMessage(userMessage);
    return result.response.text();
  } catch (err) {
    console.error('[chatbot] Gemini error:', err.message);
    // graceful fallback - don't crash the whole request
    return "Sorry, I'm having trouble connecting right now. Try asking about a specific reading using the options below.";
  }
}

module.exports = { getOrCreateSession, getHistory, handleMessage };
