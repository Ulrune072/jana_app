const supabase    = require('../../config/supabase');
const nodemailer  = require('nodemailer');

// Gmail SMTP transporter.
// You MUST use an App Password here - not your real Gmail password.
// Google blocks regular password auth for SMTP.
// Setup: myaccount.google.com -> Security -> 2FA -> App Passwords
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.GMAIL_USER,
    pass: process.env.GMAIL_APP_PASSWORD,
  },
});

// ─── createAlert ─────────────────────────────────────────────────────────────
async function createAlert(userId, readingId, biomarkerType, severity, message) {
  // first save the alert row so we have an audit trail
  // even if the email fails, the alert is still recorded
  const { data: alert, error } = await supabase
    .from('alerts')
    .insert({
      user_id:        userId,
      reading_id:     readingId,
      biomarker_type: biomarkerType,
      severity,
      message,
    })
    .select()
    .single();

  if (error) {
    console.error('[alerts] failed to save alert:', error.message);
    return;
  }

  // get the user's profile to find doctor_email and their name
  const { data: profile } = await supabase
    .from('profiles')
    .select('full_name, doctor_email')
    .eq('id', userId)
    .single();

  if (!profile?.doctor_email) {
    // no doctor email set - nothing to send, just log it
    console.log(`[alerts] no doctor_email for user ${userId}, skipping email`);
    return;
  }

  // send the email and update notified_at on success
  try {
    await sendAlertEmail(profile, alert);

    await supabase
      .from('alerts')
      .update({ notified_at: new Date().toISOString() })
      .eq('id', alert.id);

    console.log(`[alerts] email sent to ${profile.doctor_email}`);
  } catch (emailErr) {
    // email failed but alert row is already saved - that's acceptable
    console.error('[alerts] email send failed:', emailErr.message);
  }
}

// ─── sendAlertEmail ───────────────────────────────────────────────────────────
async function sendAlertEmail(profile, alert) {
  const severityLabel = alert.severity === 'critical' ? '🔴 CRITICAL' : '🟡 WARNING';

  await transporter.sendMail({
    from:    `"JANA Health App" <${process.env.GMAIL_USER}>`,
    to:      profile.doctor_email,
    subject: `JANA ${severityLabel}: ${alert.message.split('—')[0].trim()} for ${profile.full_name}`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background: ${alert.severity === 'critical' ? '#e53935' : '#fb8c00'};
                    padding: 20px; border-radius: 8px 8px 0 0;">
          <h2 style="color: white; margin: 0;">
            ${severityLabel} Health Alert
          </h2>
        </div>
        <div style="background: #f9f9f9; padding: 24px; border-radius: 0 0 8px 8px;
                    border: 1px solid #eee;">
          <p style="font-size: 16px; color: #333;">
            A health reading for your patient <strong>${profile.full_name}</strong>
            has triggered an alert.
          </p>
          <div style="background: white; border-left: 4px solid
               ${alert.severity === 'critical' ? '#e53935' : '#fb8c00'};
               padding: 16px; margin: 16px 0; border-radius: 4px;">
            <p style="margin: 0; font-size: 15px; color: #333;">
              ${alert.message}
            </p>
          </div>
          <p style="color: #888; font-size: 13px;">
            Recorded at: ${new Date(alert.created_at).toLocaleString()}<br>
            This is an automated alert from the JANA health monitoring system.
          </p>
        </div>
      </div>
    `,
  });
}

// ─── getAlerts ────────────────────────────────────────────────────────────────
async function getAlerts(userId) {
  const { data, error } = await supabase
    .from('alerts')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(50);

  if (error) throw new Error(error.message);
  return data;
}

// ─── markRead ────────────────────────────────────────────────────────────────
// used for the unread badge - we store read status in notified_at for now
// in a real app you'd add a separate `read_at` column
async function getUnreadCount(userId) {
  const { count } = await supabase
    .from('alerts')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId)
    .is('notified_at', null); // using notified_at as "unseen" proxy for MVP

  return count || 0;
}

module.exports = { createAlert, getAlerts, getUnreadCount };
