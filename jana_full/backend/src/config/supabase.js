const { createClient } = require('@supabase/supabase-js');

// service role key bypasses RLS - only use on the backend, never expose to Flutter
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

module.exports = supabase;
