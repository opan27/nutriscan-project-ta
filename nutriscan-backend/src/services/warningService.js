/**
 * NutriScan - Sistem Pakar Health Warning
 * Memberikan label: green, yellow, red berdasarkan kondisi medis pengguna
 */

const RULES = {
  diabetes: {
    sugar: [
      { min: 15, level: 'red',    reason: 'Kandungan gula sangat tinggi, berbahaya untuk penderita diabetes' },
      { min: 8,  level: 'yellow', reason: 'Kandungan gula cukup tinggi, batasi konsumsinya' },
    ],
    carbohydrates: [
      { min: 50, level: 'red',    reason: 'Karbohidrat tinggi dapat meningkatkan gula darah drastis' },
      { min: 30, level: 'yellow', reason: 'Karbohidrat cukup tinggi, perhatikan porsinya' },
    ],
  },
  hypertension: {
    sodium: [
      { min: 400, level: 'red',    reason: 'Kandungan natrium sangat tinggi, berbahaya untuk hipertensi' },
      { min: 200, level: 'yellow', reason: 'Kandungan natrium cukup tinggi, batasi konsumsinya' },
    ],
    fat: [
      { min: 20, level: 'red',    reason: 'Lemak tinggi dapat memperburuk tekanan darah' },
      { min: 12, level: 'yellow', reason: 'Lemak cukup tinggi, perhatikan porsinya' },
    ],
  },
  cholesterol: {
    fat: [
      { min: 25, level: 'red',    reason: 'Kandungan lemak sangat tinggi, berbahaya untuk kolesterol' },
      { min: 15, level: 'yellow', reason: 'Lemak cukup tinggi, konsumsi secukupnya' },
    ],
  },
  kidney: {
    protein: [
      { min: 20, level: 'red',    reason: 'Protein tinggi membebani fungsi ginjal' },
      { min: 12, level: 'yellow', reason: 'Protein cukup tinggi, perhatikan asupan total harian' },
    ],
    sodium: [
      { min: 300, level: 'red',    reason: 'Natrium tinggi berbahaya untuk penyakit ginjal' },
      { min: 150, level: 'yellow', reason: 'Natrium cukup tinggi untuk kondisi ginjal' },
    ],
  },
};

const LEVEL_PRIORITY = { red: 3, yellow: 2, green: 1 };

/**
 * @param {Object} food         - data nutrisi per 100g dari tabel foods
 * @param {string} conditions   - medical_condition dari health_profiles (SET field)
 * @param {number} portionG     - porsi yang dikonsumsi dalam gram
 * @returns {{ level: string, reasons: string[] }}
 */
const calculateWarning = (food, conditions, portionG = 100) => {
  // Normalkan ke porsi aktual
  const factor  = portionG / 100;
  const serving = {
    sugar:         (food.sugar         || 0) * factor,
    sodium:        (food.sodium        || 0) * factor,
    carbohydrates: (food.carbohydrates || 0) * factor,
    fat:           (food.fat           || 0) * factor,
    protein:       (food.protein       || 0) * factor,
    calories:      (food.calories      || 0) * factor,
  };

  let maxLevel = 'green';
  const reasons = [];

  // Parse kondisi medis (MySQL SET disimpan sebagai string "diabetes,hypertension")
  const condList = (conditions || 'none').split(',').map(c => c.trim());

  condList.forEach((condition) => {
    const condRules = RULES[condition];
    if (!condRules) return;

    Object.entries(condRules).forEach(([nutrient, thresholds]) => {
      const value = serving[nutrient];
      for (const rule of thresholds) {
        if (value >= rule.min) {
          if (LEVEL_PRIORITY[rule.level] > LEVEL_PRIORITY[maxLevel]) {
            maxLevel = rule.level;
          }
          reasons.push(rule.reason);
          break; // ambil rule pertama yang cocok (paling ketat)
        }
      }
    });
  });

  return {
    level:   maxLevel,
    reasons: [...new Set(reasons)], // deduplikasi
  };
};

/**
 * Label teks untuk Flutter
 */
const getLevelLabel = (level) => {
  const map = {
    green:  { text: 'Aman',   color: '#4CAF50', emoji: '✅' },
    yellow: { text: 'Batasi', color: '#FFC107', emoji: '⚠️' },
    red:    { text: 'Hindari', color: '#F44336', emoji: '🚫' },
  };
  return map[level] || map.green;
};

module.exports = { calculateWarning, getLevelLabel };
