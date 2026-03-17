const express  = require('express');
const supabase  = require('../../config/supabase');
const { createClient } = require('@supabase/supabase-js');

const router = express.Router();

// POST /api/auth/profile  — create or update profile
router.post('/profile', async (req, res, next) => {
  try {
    const {
      full_name, date_of_birth, gender,
      doctor_email, height_cm, weight_kg,
    } = req.body;

    if (!full_name) return res.status(400).json({ error: 'full_name is required' });

    const { data, error } = await supabase
      .from('profiles')
      .upsert(
        {
          id: req.user.id,
          full_name,
          date_of_birth: date_of_birth || null,
          gender:        gender        || null,
          doctor_email:  doctor_email  || null,
          height_cm:     height_cm     || null,
          weight_kg:     weight_kg     || null,
        },
        { onConflict: 'id' }
      )
      .select()
      .single();

    if (error) throw new Error(error.message);
    res.json({ profile: data });
  } catch (err) {
    next(err);
  }
});

// GET /api/auth/profile
router.get('/profile', async (req, res, next) => {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', req.user.id)
      .single();

    if (error) throw new Error(error.message);
    res.json({ profile: data });
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/avatar
// Uploads a profile picture to Supabase Storage and saves the public URL
router.post('/avatar', async (req, res, next) => {
  try {
    const { base64, mimeType } = req.body;
    if (!base64 || !mimeType) {
      return res.status(400).json({ error: 'base64 and mimeType are required' });
    }

    const buffer   = Buffer.from(base64, 'base64');
    const ext      = mimeType.split('/')[1]; // e.g. 'jpeg'
    const filePath = `avatars/${req.user.id}.${ext}`;

    // use a Supabase client initialised with service role to bypass storage RLS
    const adminClient = createClient(
      process.env.SUPABASE_URL,
      process.env.SUPABASE_SERVICE_ROLE_KEY
    );

    const { error: uploadError } = await adminClient.storage
      .from('avatars')
      .upload(filePath, buffer, {
        contentType: mimeType,
        upsert: true,  // overwrite if avatar already exists
      });

    if (uploadError) throw new Error(uploadError.message);

    const { data: urlData } = adminClient.storage
      .from('avatars')
      .getPublicUrl(filePath);

    // save the URL to the profile row
    await supabase
      .from('profiles')
      .update({ avatar_url: urlData.publicUrl })
      .eq('id', req.user.id);

    res.json({ avatar_url: urlData.publicUrl });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
