/**
 * NutriScan - BMI & BMR Calculator Service
 * Rumus: Harris-Benedict (revised Mifflin-St Jeor)
 */

const ACTIVITY_MULTIPLIER = {
  sedentary:   1.2,
  light:       1.375,
  moderate:    1.55,
  active:      1.725,
  very_active: 1.9,
};

/**
 * Hitung BMI
 * @param {number} weightKg
 * @param {number} heightCm
 * @returns {number}
 */
const calculateBMI = (weightKg, heightCm) => {
  const heightM = heightCm / 100;
  return parseFloat((weightKg / (heightM * heightM)).toFixed(2));
};

/**
 * Kategori BMI
 */
const getBMICategory = (bmi) => {
  if (bmi < 18.5) return { category: 'Kurus',         color: '#2196F3' };
  if (bmi < 25.0) return { category: 'Normal',        color: '#4CAF50' };
  if (bmi < 30.0) return { category: 'Kegemukan',     color: '#FFC107' };
  return               { category: 'Obesitas',       color: '#F44336' };
};

/**
 * Hitung BMR (Mifflin-St Jeor)
 * @param {number} weightKg
 * @param {number} heightCm
 * @param {number} age
 * @param {'male'|'female'} gender
 * @returns {number} BMR dalam kalori/hari
 */
const calculateBMR = (weightKg, heightCm, age, gender) => {
  let bmr = 10 * weightKg + 6.25 * heightCm - 5 * age;
  bmr += gender === 'male' ? 5 : -161;
  return parseFloat(bmr.toFixed(2));
};

/**
 * Hitung Total Daily Energy Expenditure (TDEE)
 * @param {number} bmr
 * @param {string} activityLevel
 * @returns {number}
 */
const calculateTDEE = (bmr, activityLevel) => {
  const multiplier = ACTIVITY_MULTIPLIER[activityLevel] || 1.2;
  return parseFloat((bmr * multiplier).toFixed(2));
};

module.exports = { calculateBMI, getBMICategory, calculateBMR, calculateTDEE };
