const express  = require('express');
const supabase  = require('../../config/supabase');

const router = express.Router();

// GET /api/profile
router.get('/', async (req, res, next) => {
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

// PATCH /api/profile
// Only updates the fields that are actually sent - ignores the rest
router.patch('/', async (req, res, next) => {
  try {
    const allowed = [
      'full_name', 'date_of_birth', 'gender',
      'doctor_email', 'height_cm', 'weight_kg', 'avatar_url',
    ];

    // pick only allowed fields from request body
    const updates = {};
    for (const field of allowed) {
      if (req.body[field] !== undefined) {
        updates[field] = req.body[field];
      }
    }

    if (Object.keys(updates).length === 0) {
      return res.status(400).json({ error: 'No valid fields to update' });
    }

    const { data, error } = await supabase
      .from('profiles')
      .update(updates)
      .eq('id', req.user.id)
      .select()
      .single();

    if (error) throw new Error(error.message);
    res.json({ profile: data });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
