// src/services/expertSystemService.js
// Forward Chaining — DUA FUNGSI:
// 1. generateRecommendation() → rekomendasi proaktif dari profil
// 2. checkNutritionWarning()  → warning reaktif dari log makan

// ─── Knowledge Base: Rule untuk Rekomendasi ──────────────────
const RECOMMENDATION_RULES = [

  // ── DM Tipe 2 ─────────────────────────────────────────────
  {
    id: 'R_DM_01',
    condition: (f) => f.conditions.includes('diabetes') && f.blood_sugar_fasting > 126,
    action: {
      meal_pattern: 'Makan 3x utama + 2 snack kecil per hari, jarak makan max 4 jam',
      allowed_foods: ['Nasi merah', 'Oat', 'Kentang rebus', 'Ubi', 'Sayuran hijau', 'Ikan', 'Tempe', 'Tahu', 'Telur rebus', 'Buah rendah GI (apel, pir, jeruk)'],
      avoided_foods: ['Nasi putih berlebih', 'Roti putih', 'Minuman manis', 'Martabak manis', 'Kue-kue manis', 'Gorengan', 'Sirup', 'Minuman bersoda'],
      max_sugar_g: 25,
      max_carbs_g: 225,
      fired_rule: 'R_DM_01',
    },
  },
  {
    id: 'R_DM_02',
    condition: (f) => f.conditions.includes('diabetes') && (f.blood_sugar_fasting === null || f.blood_sugar_fasting <= 126),
    action: {
      meal_pattern: 'Makan teratur 3x sehari, porsi terkontrol sesuai BMR',
      allowed_foods: ['Nasi merah atau nasi putih porsi kecil', 'Lauk protein rendah lemak', 'Sayuran bebas', 'Buah segar 2 porsi/hari'],
      avoided_foods: ['Gula tambahan berlebih', 'Makanan olahan tinggi gula', 'Gorengan setiap hari'],
      max_sugar_g: 30,
      max_carbs_g: 250,
      fired_rule: 'R_DM_02',
    },
  },

  // ── Hipertensi ─────────────────────────────────────────────
  {
    id: 'R_HT_01',
    condition: (f) => f.conditions.includes('hypertension') && f.blood_pressure_systolic >= 160,
    action: {
      meal_pattern: 'Diet DASH ketat — hindari garam & lemak jenuh, perbanyak kalium',
      allowed_foods: ['Pisang', 'Alpukat', 'Sayuran hijau', 'Ikan salmon/tuna', 'Kacang-kacangan', 'Susu rendah lemak', 'Biji-bijian'],
      avoided_foods: ['Garam dapur berlebih', 'Makanan kaleng', 'Acar', 'Kerupuk', 'Fast food', 'Daging olahan (sosis, nugget)', 'Jeroan'],
      max_sodium_mg: 1200,
      fired_rule: 'R_HT_01',
    },
  },
  {
    id: 'R_HT_02',
    condition: (f) => f.conditions.includes('hypertension') && (f.blood_pressure_systolic === null || f.blood_pressure_systolic < 160),
    action: {
      meal_pattern: 'Diet DASH — kurangi natrium, tingkatkan asupan buah dan sayur',
      allowed_foods: ['Buah segar', 'Sayuran beragam', 'Protein tanpa lemak', 'Biji-bijian utuh'],
      avoided_foods: ['Makanan asin berlebih', 'Makanan kaleng', 'Fast food', 'Alkohol'],
      max_sodium_mg: 1500,
      fired_rule: 'R_HT_02',
    },
  },

  // ── Komorbid DM + Hipertensi ───────────────────────────────
  {
    id: 'R_COMBO_01',
    condition: (f) => f.conditions.includes('diabetes') && f.conditions.includes('hypertension'),
    action: {
      meal_pattern: 'Diet kombinasi DM + DASH: rendah gula & rendah garam, porsi terkontrol',
      allowed_foods: ['Nasi merah', 'Sayuran hijau tanpa garam berlebih', 'Ikan kukus/panggang', 'Tempe/tahu rebus', 'Buah rendah GI dan kalium tinggi (pisang, alpukat)'],
      avoided_foods: ['Gula tambahan', 'Garam berlebih', 'Makanan kaleng', 'Gorengan', 'Fast food', 'Minuman manis', 'Makanan olahan'],
      max_sugar_g: 20,
      max_sodium_mg: 1200,
      max_carbs_g: 200,
      fired_rule: 'R_COMBO_01',
    },
  },
];

// ─── Knowledge Base: Rule untuk Olahraga ─────────────────────
const EXERCISE_RULES = [
  {
    id: 'E_DM_SEDENTARY',
    condition: (f) => f.conditions.includes('diabetes') && f.activity_level === 'sedentary' && f.bmi < 30,
    action: {
      exercise_type: 'Jalan kaki atau senam ringan',
      exercise_duration_min: 30,
      exercise_freq: '5x per minggu',
      exercise_notes: 'Mulai bertahap 10 menit/hari, tingkatkan setiap minggu. Lakukan setelah makan (1–2 jam). Hindari olahraga saat gula darah < 100 mg/dL.',
    },
  },
  {
    id: 'E_DM_OBESE',
    condition: (f) => f.conditions.includes('diabetes') && f.bmi >= 30,
    action: {
      exercise_type: 'Jalan kaki ringan atau renang',
      exercise_duration_min: 20,
      exercise_freq: '3–5x per minggu',
      exercise_notes: 'Hindari olahraga berat. Prioritaskan jalan kaki atau berenang untuk mengurangi tekanan sendi. Konsultasikan dengan dokter sebelum memulai.',
    },
  },
  {
    id: 'E_HT_GENERAL',
    condition: (f) => f.conditions.includes('hypertension') && !f.conditions.includes('diabetes'),
    action: {
      exercise_type: 'Aerobik intensitas sedang: jalan cepat, bersepeda, renang',
      exercise_duration_min: 30,
      exercise_freq: '5x per minggu',
      exercise_notes: 'Hindari olahraga isometrik (angkat beban berat). Ukur tekanan darah sebelum berolahraga. Hentikan jika kepala pusing atau nyeri dada.',
    },
  },
  {
    id: 'E_COMBO',
    condition: (f) => f.conditions.includes('diabetes') && f.conditions.includes('hypertension'),
    action: {
      exercise_type: 'Jalan kaki santai atau senam ringan',
      exercise_duration_min: 30,
      exercise_freq: '5x per minggu (150 menit/minggu)',
      exercise_notes: 'Kombinasi kondisi DM dan Hipertensi — mulai perlahan, pantau tekanan darah dan gula darah sebelum dan sesudah. Wajib konsultasi dokter untuk program olahraga.',
    },
  },
  {
    id: 'E_DEFAULT',
    condition: (f) => true, // fallback
    action: {
      exercise_type: 'Jalan kaki santai',
      exercise_duration_min: 30,
      exercise_freq: '3–5x per minggu',
      exercise_notes: 'Aktivitas fisik ringan-sedang dianjurkan untuk semua kondisi. Mulai dari yang ringan dan tingkatkan secara bertahap.',
    },
  },
];

// ─── Knowledge Base: Rule untuk Warning Monitoring ───────────
const WARNING_RULES = {
  diabetes: {
    sugar:         [{ min: 20, level: 'red', reason: 'Konsumsi gula hari ini sudah melampaui batas aman DM Tipe 2. Hindari makanan manis sampai besok.' },
                   { min: 15, level: 'yellow', reason: 'Konsumsi gula mendekati batas. Batasi asupan manis selanjutnya.' }],
    carbohydrates: [{ min: 230, level: 'red', reason: 'Karbohidrat hari ini terlalu tinggi untuk penderita DM. Pilih sayuran untuk makan berikutnya.' },
                   { min: 180, level: 'yellow', reason: 'Karbohidrat cukup tinggi. Batasi nasi/roti untuk sisa hari ini.' }],
    calories:      [{ minPct: 100, level: 'red', reason: 'Target kalori harian sudah tercapai. Hentikan makan besar.' },
                   { minPct: 90,  level: 'yellow', reason: 'Kalori hampir mencapai target. Pilih makanan ringan untuk sisa hari ini.' }],
  },
  hypertension: {
    sodium:   [{ min: 1400, level: 'red', reason: 'Natrium hari ini sangat tinggi untuk penderita Hipertensi. Hindari garam dan makanan asin sampai besok.' },
               { min: 1100, level: 'yellow', reason: 'Natrium mendekati batas. Hindari makanan asin untuk sisa hari ini.' }],
    fat:      [{ min: 50, level: 'red', reason: 'Lemak hari ini terlalu tinggi. Hindari gorengan dan daging berlemak.' },
               { min: 35, level: 'yellow', reason: 'Konsumsi lemak cukup tinggi. Pilih makanan rendah lemak selanjutnya.' }],
  },
};

// ═══════════════════════════════════════════════════════════════
// FUNGSI 1: Rekomendasi Proaktif (dari profil)
// ═══════════════════════════════════════════════════════════════
const generateRecommendation = (profile) => {
  const facts = {
    conditions:              (profile.medical_condition || 'none').split(',').map(c => c.trim()),
    bmi:                     parseFloat(profile.bmi) || 0,
    bmr:                     parseFloat(profile.bmr) || 0,
    daily_calorie_target:    parseFloat(profile.daily_calorie_target) || 2000,
    activity_level:          profile.activity_level || 'sedentary',
    blood_sugar_fasting:     profile.blood_sugar_fasting ? parseFloat(profile.blood_sugar_fasting) : null,
    blood_pressure_systolic: profile.blood_pressure_systolic ? parseInt(profile.blood_pressure_systolic) : null,
    age:                     profile.age || 0,
    gender:                  profile.gender || 'male',
  };

  const firedRules   = [];
  let foodResult     = { allowed_foods: [], avoided_foods: [], meal_pattern: 'Makan teratur 3x sehari dengan porsi seimbang', max_sugar_g: 50, max_sodium_mg: 2000, max_carbs_g: 300 };
  let exerciseResult = null;

  // ── Jalankan rule makanan (Forward Chaining) ──
  // Prioritas: COMBO > kondisi spesifik
  for (const rule of RECOMMENDATION_RULES) {
    if (rule.condition(facts)) {
      firedRules.push(rule.id);
      // Merge hasil — jika sudah ada COMBO, skip rule individual
      if (rule.id === 'R_COMBO_01') {
        foodResult = { ...foodResult, ...rule.action };
        break; // COMBO rule override semua
      }
      foodResult = { ...foodResult, ...rule.action };
    }
  }

  // ── Jalankan rule olahraga (Forward Chaining) ──
  for (const rule of EXERCISE_RULES) {
    if (rule.condition(facts)) {
      firedRules.push(rule.id);
      exerciseResult = rule.action;
      if (rule.id !== 'E_DEFAULT') break; // ambil rule pertama yang cocok (bukan fallback)
    }
  }

  // ── Hitung target nutrisi dari BMR ──
  const targetCalories = facts.daily_calorie_target;
  const minProtein     = Math.round((targetCalories * 0.15) / 4); // 15% dari kalori / 4 kcal/g

  return {
    fired_rules:    firedRules,
    food: {
      meal_pattern:  foodResult.meal_pattern,
      allowed_foods: foodResult.allowed_foods,
      avoided_foods: foodResult.avoided_foods,
    },
    nutrition_targets: {
      daily_calories: targetCalories,
      max_sugar_g:    foodResult.max_sugar_g   || 50,
      max_sodium_mg:  foodResult.max_sodium_mg || 2000,
      max_carbs_g:    foodResult.max_carbs_g   || 300,
      min_protein_g:  minProtein,
      max_fat_g:      Math.round(targetCalories * 0.25 / 9), // 25% dari kalori / 9 kcal/g
    },
    exercise: exerciseResult || EXERCISE_RULES[EXERCISE_RULES.length - 1].action,
  };
};

// ═══════════════════════════════════════════════════════════════
// FUNGSI 2: Warning Reaktif (dari log makan harian)
// ═══════════════════════════════════════════════════════════════
const checkNutritionWarning = (todayNutrition, profile, recommendation) => {
  const conditions    = (profile.medical_condition || 'none').split(',').map(c => c.trim());
  const targetCalories = parseFloat(profile.daily_calorie_target) || 2000;
  const caloriePct    = (todayNutrition.calories / targetCalories) * 100;

  const PRIORITY = { red: 3, yellow: 2, green: 1 };
  let maxLevel   = 'green';
  const warnings = [];
  const firedRules = [];

  const checkRules = (conditionRules, nutrientValues) => {
    Object.entries(conditionRules).forEach(([nutrient, thresholds]) => {
      let value;
      if (nutrient === 'calories') {
        value = caloriePct; // gunakan persentase untuk kalori
      } else {
        value = parseFloat(todayNutrition[nutrient] || 0);
      }

      for (const rule of thresholds) {
        const threshold = nutrient === 'calories' ? rule.minPct : rule.min;
        if (value >= threshold) {
          if (PRIORITY[rule.level] > PRIORITY[maxLevel]) maxLevel = rule.level;
          warnings.push({ level: rule.level, message: rule.reason, nutrient });
          firedRules.push(`W_${nutrient.toUpperCase()}_${rule.level.toUpperCase()}`);
          break;
        }
      }
    });
  };

  if (conditions.includes('diabetes'))    checkRules(WARNING_RULES.diabetes,    todayNutrition);
  if (conditions.includes('hypertension')) checkRules(WARNING_RULES.hypertension, todayNutrition);

  // Saran makan berikutnya berdasarkan warning
  let nextMealSuggestion = '';
  if (maxLevel === 'red') {
    nextMealSuggestion = 'Makan berikutnya: sayuran kukus, protein tanpa lemak (ikan/tahu/tempe rebus), air putih. Hindari nasi dan makanan asin/manis.';
  } else if (maxLevel === 'yellow') {
    nextMealSuggestion = 'Makan berikutnya: porsi lebih kecil, pilih sayuran dan protein tanpa lemak. Batasi karbohidrat dan garam.';
  } else {
    nextMealSuggestion = 'Konsumsi hari ini masih aman. Pertahankan pola makan sehat!';
  }

  return {
    overall_level:        maxLevel,
    warnings:             warnings,
    next_meal_suggestion: nextMealSuggestion,
    calorie_percentage:   Math.round(caloriePct),
    fired_rules:          firedRules,
  };
};

// ─── Label warna untuk Flutter ───────────────────────────────
const getLevelInfo = (level) => ({
  green:  { label: 'Aman',    color: '#4CAF50', icon: 'check_circle' },
  yellow: { label: 'Batasi',  color: '#FFC107', icon: 'warning_amber' },
  red:    { label: 'Hindari', color: '#F44336', icon: 'cancel' },
})[level] || { label: 'Aman', color: '#4CAF50', icon: 'check_circle' };

module.exports = { generateRecommendation, checkNutritionWarning, getLevelInfo };