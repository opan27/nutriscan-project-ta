const db     = require('../config/db');
const PDFKit = require('pdfkit');

// GET /api/analytics/weekly
const getWeeklyInsight = async (req, res) => {
  try {
    const [rows] = await db.query(
      `SELECT
         DATE(logged_at)              AS date,
         SUM(calories_consumed)       AS total_calories,
         SUM(carbs_consumed)          AS total_carbs,
         SUM(protein_consumed)        AS total_protein,
         SUM(fat_consumed)            AS total_fat,
         SUM(sugar_consumed)          AS total_sugar,
         COUNT(*)                     AS meal_count
       FROM meal_logs
       WHERE user_id = ? AND logged_at >= DATE_SUB(CURDATE(), INTERVAL 7 DAY)
       GROUP BY DATE(logged_at)
       ORDER BY date ASC`,
      [req.user.id]
    );

    // Bandingkan rata-rata minggu ini vs minggu lalu
    const [prevWeek] = await db.query(
      `SELECT
         AVG(calories_consumed) AS avg_cal,
         AVG(sugar_consumed)    AS avg_sugar
       FROM meal_logs
       WHERE user_id = ?
         AND logged_at BETWEEN DATE_SUB(CURDATE(), INTERVAL 14 DAY)
                           AND DATE_SUB(CURDATE(), INTERVAL 8 DAY)`,
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
  const days = parseInt(req.query.days) || 7;

  try {
    const [userRows] = await db.query('SELECT name, email FROM users WHERE id = ?', [req.user.id]);
    const user = userRows[0];

    const [logs] = await db.query(
      `SELECT ml.*, f.name AS food_name, f.category
       FROM meal_logs ml
       JOIN foods f ON ml.food_id = f.id
       WHERE ml.user_id = ? AND ml.logged_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
       ORDER BY ml.logged_at DESC`,
      [req.user.id, days]
    );

    const [profile] = await db.query(
      'SELECT * FROM health_profiles WHERE user_id = ?',
      [req.user.id]
    );

    // Generate PDF
    const doc = new PDFKit({ margin: 50, size: 'A4' });

    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=nutriscan-report-${Date.now()}.pdf`);
    doc.pipe(res);

    // Header
    doc.fontSize(22).font('Helvetica-Bold').text('NutriScan', { align: 'center' });
    doc.fontSize(14).font('Helvetica').text('Laporan Riwayat Makan', { align: 'center' });
    doc.moveDown();
    doc.fontSize(11).text(`Nama  : ${user.name}`);
    doc.text(`Email : ${user.email}`);
    doc.text(`Periode: ${days} hari terakhir`);
    doc.text(`Dicetak: ${new Date().toLocaleDateString('id-ID', { dateStyle: 'long' })}`);

    if (profile.length > 0) {
      const p = profile[0];
      doc.moveDown();
      doc.font('Helvetica-Bold').text('Profil Kesehatan:');
      doc.font('Helvetica')
         .text(`BMI: ${p.bmi} (${p.bmi < 18.5 ? 'Kurus' : p.bmi < 25 ? 'Normal' : 'Kegemukan'})`)
         .text(`Target Kalori Harian: ${p.daily_calorie_target} kkal`)
         .text(`Kondisi Medis: ${p.medical_condition || 'Tidak ada'}`);
    }

    doc.moveDown();
    doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke();
    doc.moveDown();

    // Table header
    doc.font('Helvetica-Bold').fontSize(10);
    doc.text('Tanggal',    50,  doc.y, { width: 90 });
    doc.text('Makanan',    140, doc.y - 12, { width: 130 });
    doc.text('Jenis',      270, doc.y - 12, { width: 70 });
    doc.text('Porsi (g)',  340, doc.y - 12, { width: 60 });
    doc.text('Kalori',     400, doc.y - 12, { width: 60 });
    doc.text('Gula (g)',   460, doc.y - 12, { width: 60 });
    doc.moveDown(0.3);
    doc.moveTo(50, doc.y).lineTo(545, doc.y).stroke();
    doc.moveDown(0.3);

    // Table rows
    doc.font('Helvetica').fontSize(9);
    logs.forEach((log) => {
      if (doc.y > 700) doc.addPage();
      const date = new Date(log.logged_at).toLocaleDateString('id-ID');
      const y = doc.y;
      doc.text(date,                    50,  y, { width: 90 });
      doc.text(log.food_name,           140, y, { width: 130 });
      doc.text(log.meal_type,           270, y, { width: 70 });
      doc.text(`${log.portion_g}g`,     340, y, { width: 60 });
      doc.text(`${log.calories_consumed} kkal`, 400, y, { width: 60 });
      doc.text(`${log.sugar_consumed}g`, 460, y, { width: 60 });
      doc.moveDown(0.6);
    });

    doc.moveDown();
    doc.font('Helvetica-BoldOblique').fontSize(9)
       .text('Laporan ini dibuat otomatis oleh aplikasi NutriScan. Konsultasikan dengan dokter untuk saran medis.', {
         align: 'center', color: 'gray'
       });

    doc.end();
  } catch (err) {
    console.error(err);
    return res.status(500).json({ success: false, message: 'Gagal membuat PDF' });
  }
};

module.exports = { getWeeklyInsight, exportPDF };
