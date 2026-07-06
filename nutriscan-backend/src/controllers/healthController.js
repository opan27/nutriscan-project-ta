// src/controllers/healthController.js (UPDATED)
const db = require('../config/db');
const { calculateBMI, getBMICategory, calculateBMR, calculateTDEE } = require('../services/bmiService');
const { generateRecommendation } = require('../services/expertSystemService');

// POST /api/health/profile  (create or update)
const upsertProfile = async (req, res) => {
  // ✅ FIX: Parse & sanitasi semua input sebelum diproses
  const weight_kg              = parseFloat(req.body.weight_kg);
  const height_cm              = Math.round(parseFloat(req.body.height_cm)); // bulatkan ke int
  const age                    = parseInt(req.body.age);
  const gender                 = req.body.gender;
  const activity_level         = req.body.activity_level || 'sedentary';
  const medical_condition      = req.body.medical_condition || 'none';
  const blood_sugar_fasting    = req.body.blood_sugar_fasting
                                   ? parseFloat(req.body.blood_sugar_fasting)
                                   : null;
  const blood_pressure_systolic = req.body.blood_pressure_systolic
                                   ? parseInt(req.body.blood_pressure_systolic)
                                   : null;
  const blood_pressure_diastolic = req.body.blood_pressure_diastolic
                                   ? parseInt(req.body.blood_pressure_diastolic)
                                   : null;

  // Validasi wajib
  if (!weight_kg || !height_cm || !age || !gender) {
    return res.status(400).json({ success: false, message: 'Data fisik tidak lengkap' });
  }

  // Validasi range wajar
  if (height_cm < 50 || height_cm > 300) {
    return res.status(400).json({ success: false, message: `Tinggi badan tidak valid: ${height_cm} cm` });
  }
  if (weight_kg < 10 || weight_kg > 500) {
    return res.status(400).json({ success: false, message: `Berat badan tidak valid: ${weight_kg} kg` });
  }
  if (age < 1 || age > 120) {
    return res.status(400).json({ success: false, message: `Usia tidak valid: ${age} tahun` });
  }

  try {
    const bmi  = calculateBMI(weight_kg, height_cm);
    const bmr  = calculateBMR(weight_kg, height_cm, age, gender);
    const tdee = calculateTDEE(bmr, activity_level);

    // Simpan atau update profil
    await db.query(
      `INSERT INTO health_profiles
         (user_id, weight_kg, height_cm, age, gender, activity_level,
          medical_condition, bmi, bmr, daily_calorie_target,
          blood_sugar_fasting, blood_pressure_systolic, blood_pressure_diastolic)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
       ON DUPLICATE KEY UPDATE
         weight_kg=VALUES(weight_kg), height_cm=VALUES(height_cm),
         age=VALUES(age), gender=VALUES(gender),
         activity_level=VALUES(activity_level),
         medical_condition=VALUES(medical_condition),
         bmi=VALUES(bmi), bmr=VALUES(bmr),
         daily_calorie_target=VALUES(daily_calorie_target),
         blood_sugar_fasting=VALUES(blood_sugar_fasting),
         blood_pressure_systolic=VALUES(blood_pressure_systolic),
         blood_pressure_diastolic=VALUES(blood_pressure_diastolic)`,
      [req.user.id, weight_kg, height_cm, age, gender,
       activity_level, medical_condition,
       bmi, bmr, tdee,
       blood_sugar_fasting,
       blood_pressure_systolic,
       blood_pressure_diastolic]
    );

    // ── Jalankan Forward Chaining → generate rekomendasi ──
    const profileData = {
      medical_condition,
      bmi, bmr,
      daily_calorie_target: tdee,
      activity_level,
      blood_sugar_fasting,
      blood_pressure_systolic,
      age, gender,
    };

    const recommendation = generateRecommendation(profileData);

    // Simpan rekomendasi ke tabel recommendations
    await db.query(
      `INSERT INTO recommendations
         (user_id, allowed_foods, avoided_foods, meal_pattern,
          daily_calories, max_sugar_g, max_sodium_mg, max_carbs_g,
          min_protein_g, max_fat_g,
          exercise_type, exercise_duration_min, exercise_freq, exercise_notes,
          fired_rules)
       VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
       ON DUPLICATE KEY UPDATE
         allowed_foods=VALUES(allowed_foods),
         avoided_foods=VALUES(avoided_foods),
         meal_pattern=VALUES(meal_pattern),
         daily_calories=VALUES(daily_calories),
         max_sugar_g=VALUES(max_sugar_g),
         max_sodium_mg=VALUES(max_sodium_mg),
         max_carbs_g=VALUES(max_carbs_g),
         min_protein_g=VALUES(min_protein_g),
         max_fat_g=VALUES(max_fat_g),
         exercise_type=VALUES(exercise_type),
         exercise_duration_min=VALUES(exercise_duration_min),
         exercise_freq=VALUES(exercise_freq),
         exercise_notes=VALUES(exercise_notes),
         fired_rules=VALUES(fired_rules)`,
      [req.user.id,
       JSON.stringify(recommendation.food.allowed_foods),
       JSON.stringify(recommendation.food.avoided_foods),
       recommendation.food.meal_pattern,
       recommendation.nutrition_targets.daily_calories,
       recommendation.nutrition_targets.max_sugar_g,
       recommendation.nutrition_targets.max_sodium_mg,
       recommendation.nutrition_targets.max_carbs_g,
       recommendation.nutrition_targets.min_protein_g,
       recommendation.nutrition_targets.max_fat_g,
       recommendation.exercise.exercise_type,
       recommendation.exercise.exercise_duration_min,
       recommendation.exercise.exercise_freq,
       recommendation.exercise.exercise_notes,
       JSON.stringify(recommendation.fired_rules)]
    );

    // Tandai onboarding selesai
    await db.query(
      'UPDATE users SET onboarding_completed = 1 WHERE id = ?',
      [req.user.id]
    );

    const bmiCat = getBMICategory(bmi);

    return res.json({
      success: true,
      message: 'Profil berhasil disimpan dan rekomendasi diperbarui',
      data: {
        bmi,
        bmi_category:         bmiCat.category,
        bmi_color:            bmiCat.color,
        bmr:                  Math.round(bmr),
        daily_calorie_target: Math.round(tdee),
        recommendation,
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Server error: ' + err.message });
  }
};

// GET /api/health/profile
const getProfile = async (req, res) => {
  try {
    const [profiles] = await db.query(
      'SELECT * FROM health_profiles WHERE user_id = ?',
      [req.user.id]
    );
    if (profiles.length === 0) {
      return res.status(404).json({ success: false, message: 'Profil belum diisi', needs_onboarding: true });
    }

    const p      = profiles[0];
    const bmiCat = getBMICategory(parseFloat(p.bmi));

    // Ambil rekomendasi FC
    const [recs] = await db.query(
      'SELECT * FROM recommendations WHERE user_id = ?',
      [req.user.id]
    );
    const rec = recs[0] || null;

    return res.json({
      success: true,
      data: {
        ...p,
        bmi_category: bmiCat.category,
        bmi_color:    bmiCat.color,
        recommendation: rec ? {
          food: {
            meal_pattern:  rec.meal_pattern,
            allowed_foods: JSON.parse(rec.allowed_foods || '[]'),
            avoided_foods: JSON.parse(rec.avoided_foods || '[]'),
          },
          nutrition_targets: {
            daily_calories: rec.daily_calories,
            max_sugar_g:    rec.max_sugar_g,
            max_sodium_mg:  rec.max_sodium_mg,
            max_carbs_g:    rec.max_carbs_g,
            min_protein_g:  rec.min_protein_g,
            max_fat_g:      rec.max_fat_g,
          },
          exercise: {
            exercise_type:         rec.exercise_type,
            exercise_duration_min: rec.exercise_duration_min,
            exercise_freq:         rec.exercise_freq,
            exercise_notes:        rec.exercise_notes,
          },
          fired_rules: JSON.parse(rec.fired_rules || '[]'),
        } : null,
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/health/recommendation (ambil rekomendasi saja)
const getRecommendation = async (req, res) => {
  try {
    const [recs] = await db.query(
      'SELECT * FROM recommendations WHERE user_id = ?',
      [req.user.id]
    );
    if (recs.length === 0) {
      return res.status(404).json({ success: false, message: 'Belum ada rekomendasi. Lengkapi profil terlebih dahulu.' });
    }
    const rec = recs[0];
    return res.json({
      success: true,
      data: {
        food: {
          meal_pattern:  rec.meal_pattern,
          allowed_foods: JSON.parse(rec.allowed_foods || '[]'),
          avoided_foods: JSON.parse(rec.avoided_foods || '[]'),
        },
        nutrition_targets: {
          daily_calories: rec.daily_calories,
          max_sugar_g:    rec.max_sugar_g,
          max_sodium_mg:  rec.max_sodium_mg,
          max_carbs_g:    rec.max_carbs_g,
          min_protein_g:  rec.min_protein_g,
          max_fat_g:      rec.max_fat_g,
        },
        exercise: {
          type:         rec.exercise_type,
          duration_min: rec.exercise_duration_min,
          frequency:    rec.exercise_freq,
          notes:        rec.exercise_notes,
        },
        generated_at: rec.generated_at,
        fired_rules:  JSON.parse(rec.fired_rules || '[]'),
      },
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/health/onboarding-status
const getOnboardingStatus = async (req, res) => {
  try {
    const [users] = await db.query(
      'SELECT onboarding_completed FROM users WHERE id = ?',
      [req.user.id]
    );
    const [profiles] = await db.query(
      'SELECT id FROM health_profiles WHERE user_id = ?',
      [req.user.id]
    );
    return res.json({
      success: true,
      data: {
        onboarding_completed: users[0]?.onboarding_completed === 1,
        has_profile:          profiles.length > 0,
      },
    });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { upsertProfile, getProfile, getRecommendation, getOnboardingStatus };