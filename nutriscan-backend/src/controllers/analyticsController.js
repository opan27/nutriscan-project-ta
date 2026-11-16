const db     = require('../config/db');
const PDFKit = require('pdfkit');
const { renderMealReport } = require('../services/pdfReportService');

// GET /api/analytics/weekly
const getWeeklyInsight = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT
         -- String 'YYYY-MM-DD', bukan objek Date: kalau Date, JSON mengubahnya ke UTC
         -- sehingga di WIB tanggalnya mundur 1 hari (Senin tampil sebagai Minggu)
         DATE_FORMAT(logged_at, '%Y-%m-%d') AS date,
         SUM(calories_consumed)       AS total_calories,
         SUM(carbs_consumed)          AS total_carbs,
         SUM(protein_consumed)        AS total_protein,
         SUM(fat_consumed)            AS total_fat,
         SUM(sugar_consumed)          AS total_sugar,
         COUNT(*)                     AS meal_count
       FROM meal_logs
       WHERE user_id = ? AND logged_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)
       GROUP BY DATE_FORMAT(logged_at, '%Y-%m-%d')
       ORDER BY date ASC`,
      [req.user.id]
    );

    // Minggu lalu = 7 hari sebelum minggu ini. Dihitung dengan cara yang SAMA:
    // total per hari dulu, baru dirata-rata (bukan rata-rata per item makanan).
    const [prevWeek] = await db.query(
      `SELECT
         AVG(day_cal)   AS avg_cal,
         AVG(day_sugar) AS avg_sugar
       FROM (
         SELECT DATE(logged_at)     AS d,
                SUM(calories_consumed) AS day_cal,
                SUM(sugar_consumed)    AS day_sugar
         FROM meal_logs
         WHERE user_id = ?
           AND logged_at >= DATE_SUB(CURDATE(), INTERVAL 13 DAY)
           AND logged_at <  DATE_SUB(CURDATE(), INTERVAL 6 DAY)
         GROUP BY DATE(logged_at)
       ) t`,
      [req.user.id]
    );

    const thisWeekAvgCal   = rows.reduce((s, r) => s + parseFloat(r.total_calories), 0) / (rows.length || 1);
    const thisWeekAvgSugar = rows.reduce((s, r) => s + parseFloat(r.total_sugar),    0) / (rows.length || 1);
    const prevCal          = parseFloat(prevWeek[0]?.avg_cal   || 0);
    const prevSugar        = parseFloat(prevWeek[0]?.avg_sugar || 0);

    const calChange   = prevCal   > 0 ? (((thisWeekAvgCal   - prevCal)   / prevCal)   * 100).toFixed(1) : null;
    const sugarChange = prevSugar > 0 ? (((thisWeekAvgSugar - prevSugar) / prevSugar) * 100).toFixed(1) : null;

    // Buat insight teks otomatis
    const insights = [];
    if (sugarChange !== null) {
      const dir = sugarChange > 0 ? 'meningkat' : 'menurun';
      insights.push(`Minggu ini konsumsi gula kamu ${dir} ${Math.abs(sugarChange)}% dibanding minggu lalu.`);
    }
    if (calChange !== null) {
      const dir = calChange > 0 ? 'meningkat' : 'menurun';
      insights.push(`Rata-rata kalori harian ${dir} ${Math.abs(calChange)}%.`);
    }
    if (rows.length === 0) {
      insights.push('Belum ada data minggu ini. Mulai catat makananmu!');
    }

    return res.json({
      success: true,
      data: {
        daily_stats:   rows,
        insights,
        avg_this_week: { calories: thisWeekAvgCal.toFixed(1), sugar: thisWeekAvgSugar.toFixed(1) },
        avg_last_week: { calories: prevCal.toFixed(1),        sugar: prevSugar.toFixed(1) },
        changes:       { calories_pct: calChange, sugar_pct: sugarChange },
      },
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Server error' });
  }
};

// GET /api/analytics/export-pdf
const exportPDF = async (req, res) => {
  const days = Math.min(Math.max(parseInt(req.query.days) || 7, 1), 365);

  try {
    const [[user]] = await db.query('SELECT name, email FROM users WHERE id = ?', [req.user.id]);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User tidak ditemukan' });
    }

    // Periode = `days` hari kalender terakhir, termasuk hari ini (urut kronologis)
    const [logs] = await db.query(
      `SELECT ml.*, f.name AS food_name, f.category
       FROM meal_logs ml
       JOIN foods f ON ml.food_id = f.id
       WHERE ml.user_id = ? AND ml.logged_at >= DATE_SUB(CURDATE(), INTERVAL ? DAY)
       ORDER BY ml.logged_at ASC`,
      [req.user.id, days - 1]
    );

    const [[profile]] = await db.query('SELECT * FROM health_profiles WHERE user_id = ?', [req.user.id]);
    const [[recommendation]] = await db.query(
      'SELECT max_sugar_g FROM recommendations WHERE user_id = ?',
      [req.user.id]
    ).catch(() => [[undefined]]); // tabel lama mungkin belum ada → pakai default

    // Render ke buffer dulu: kalau gagal di tengah, user dapat JSON error, bukan PDF rusak
    const doc = new PDFKit({
      size: 'A4',
      margin: 40,
      bufferPages: true, // perlu untuk footer "Halaman x dari y"
      info: { Title: 'Laporan Riwayat Makan - NutriScan', Author: 'NutriScan' },
    });
    const chunks = [];
    doc.on('data', (c) => chunks.push(c));
    const done = new Promise((resolve, reject) => {
      doc.on('end', resolve);
      doc.on('error', reject);
    });

    renderMealReport(doc, { user, profile, recommendation, logs, days });
    doc.end();
    await done;

    const pdf = Buffer.concat(chunks);
    const stamp = new Date().toISOString().slice(0, 10);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Length', pdf.length);
    res.setHeader('Content-Disposition', `inline; filename="laporan-nutriscan-${stamp}.pdf"`);
    return res.end(pdf);
  } catch (err) {
    console.error('exportPDF error:', err);
    return res.status(500).json({ success: false, message: 'Gagal membuat PDF' });
  }
};

module.exports = { getWeeklyInsight, exportPDF };
