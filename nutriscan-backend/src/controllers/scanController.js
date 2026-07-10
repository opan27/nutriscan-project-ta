const db = require('../config/db');
const { detectFood } = require('../services/yoloService');
const { calculateWarning, getLevelLabel } = require('../services/warningService');
const fs = require('fs');

// POST /api/scan/upload
const uploadAndScan = async (req, res) => {

  if (!req.file) {
    return res.status(400).json({
      success: false,
      message: 'Gambar wajib diunggah'
    });
  }

  const imagePath = req.file.path;

  try {

    // 1. YOLO DETECTION
    const result = await detectFood(imagePath);

    console.log(
      'YOLO RESULT:',
      JSON.stringify(result, null, 2)
    );

    const detections = result.detections || [];

    if (detections.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Tidak ada makanan terdeteksi'
      });
    }

    // 2. HEALTH PROFILE USER
    const [profiles] = await db.query(
      'SELECT medical_condition FROM health_profiles WHERE user_id = ?',
      [req.user.id]
    );

    const condition =
      profiles.length > 0
        ? profiles[0].medical_condition
        : 'none';

    const detectedFoods = [];

    let totalNutrition = {
      calories: 0,
      carbohydrates: 0,
      protein: 0,
      fat: 0
    };

    // 3. LOOP SEMUA HASIL DETEKSI
    for (const item of detections) {

      const label = item.label;
      const confidence = item.confidence;

      const [foods] = await db.query(
        'SELECT * FROM foods WHERE yolo_label = ?',
        [label]
      );

      if (foods.length === 0) {
        continue;
      }

      const food = foods[0];

      const portionG =
        parseFloat(req.body.portion_g) ||
        food.serving_size_g ||
        100;

      const factor = portionG / 100;

      const nutrition = {
        calories: Number(
          (food.calories * factor).toFixed(1)
        ),
        carbohydrates: Number(
          (food.carbohydrates * factor).toFixed(1)
        ),
        protein: Number(
          (food.protein * factor).toFixed(1)
        ),
        fat: Number(
          (food.fat * factor).toFixed(1)
        )
      };

      // WARNING
      const warning = calculateWarning(
        food,
        condition,
        portionG
      );

      const warningLabel = getLevelLabel(
        warning.level
      );

      // SIMPAN HISTORY
      const [scanResult] = await db.query(
        `INSERT INTO scan_history
          (
            user_id,
            food_id,
            detected_label,
            confidence_pct,
            image_path,
            warning_level,
            warning_reason
          )
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [
          req.user.id,
          food.id,
          label,
          (confidence * 100).toFixed(2),
          imagePath,
          warning.level,
          warning.reasons.join('; ')
        ]
      );

      // SIMPAN AKURASI (image_path untuk grouping multi-object per foto)
      await db.query(
        `INSERT INTO model_accuracy_logs
          (
            scan_id,
            detected_label,
            confidence_pct,
            image_path
          )
         VALUES (?, ?, ?, ?)`,
        [
          scanResult.insertId,
          label,
          (confidence * 100).toFixed(2),
          imagePath
        ]
      );

      detectedFoods.push({
        scan_id: scanResult.insertId,

        food_id: food.id,

        detected_label: label,

        food_name: food.name,

        confidence_pct: Number(
          (confidence * 100).toFixed(2)
        ),

        portion_g: portionG,

        nutrition,

        warning: {
          level: warning.level,
          label: warningLabel.text,
          color: warningLabel.color,
          reasons: warning.reasons
        },

        food_detail: {
          id: food.id,
          name: food.name,
          category: food.category
        }
      });

      // TOTAL NUTRISI
      totalNutrition.calories += nutrition.calories;
      totalNutrition.carbohydrates += nutrition.carbohydrates;
      totalNutrition.protein += nutrition.protein;
      totalNutrition.fat += nutrition.fat;
    }

    // JIKA TIDAK ADA YANG COCOK DI DATABASE
    if (detectedFoods.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Makanan terdeteksi tetapi belum ada di database nutrisi'
      });
    }

    return res.json({
      success: true,
      data: {

        total_objects: detectedFoods.length,

        foods: detectedFoods,

        total_nutrition: {
          calories: Number(
            totalNutrition.calories.toFixed(1)
          ),
          carbohydrates: Number(
            totalNutrition.carbohydrates.toFixed(1)
          ),
          protein: Number(
            totalNutrition.protein.toFixed(1)
          ),
          fat: Number(
            totalNutrition.fat.toFixed(1)
          )
        }

      }
    });

  } catch (err) {

    console.error('Scan error:', err);

    if (fs.existsSync(imagePath)) {
      fs.unlinkSync(imagePath);
    }

    return res.status(500).json({
      success: false,
      message:
        err.message ||
        'Gagal memproses gambar'
    });

  }

};

// POST /api/scan/:scanId/feedback
// User mengkoreksi hasil deteksi (untuk akurasi model)
const submitFeedback = async (req, res) => {
  const { scanId } = req.params;
  const { actual_label, is_correct } = req.body;

  try {
    await db.query(
      `UPDATE model_accuracy_logs
       SET actual_label = ?, is_correct = ?
       WHERE scan_id = ?`,
      [actual_label, is_correct ? 1 : 0, scanId]
    );
    return res.json({ success: true, message: 'Feedback disimpan, terima kasih!' });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/scan/history
const getScanHistory = async (req, res) => {
  const limit = parseInt(req.query.limit) || 20;
  const offset = parseInt(req.query.offset) || 0;

  try {
    const [rows] = await db.query(
      `SELECT sh.*, f.name AS food_name, f.calories, f.category
       FROM scan_history sh
       LEFT JOIN foods f ON sh.food_id = f.id
       WHERE sh.user_id = ?
       ORDER BY sh.scanned_at DESC
       LIMIT ? OFFSET ?`,
      [req.user.id, limit, offset]
    );
    return res.json({ success: true, data: rows });
  } catch (err) {
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

module.exports = { uploadAndScan, submitFeedback, getScanHistory };
