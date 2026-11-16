/**
 * NutriScan - Template PDF Laporan Riwayat Makan
 *
 * Struktur laporan:
 *   1. Header (judul, periode, tanggal cetak)
 *   2. Data pengguna
 *   3. Profil kesehatan (BMI, target kalori, kondisi medis, gula darah, tensi)
 *   4. Ringkasan (kartu statistik rata-rata harian vs target)
 *   5. Tabel ringkasan harian (baris merah = melebihi target kalori)
 *   6. Tabel detail catatan makan
 *   7. Footer tiap halaman (disclaimer + nomor halaman)
 */
const { getBMICategory } = require('./bmiService');

const TZ = process.env.APP_TIMEZONE || 'Asia/Jakarta';

const C = {
  primary:      '#2E7D32',
  primaryLight: '#E8F5E9',
  primaryLine:  '#C8E6C9',
  text:         '#212121',
  muted:        '#757575',
  border:       '#E0E0E0',
  zebra:        '#F7F9F7',
  red:          '#C62828',
  redLight:     '#FDECEA',
  orange:       '#EF6C00',
  orangeLight:  '#FFF3E0',
  white:        '#FFFFFF',
};

const MEAL_LABEL = {
  breakfast: 'Sarapan',
  lunch:     'Makan Siang',
  dinner:    'Makan Malam',
  snack:     'Camilan',
};

const CONDITION_LABEL = {
  none:         'Tidak ada',
  diabetes:     'Diabetes Melitus Tipe 2',
  hypertension: 'Hipertensi',
  cholesterol:  'Kolesterol Tinggi',
  kidney:       'Penyakit Ginjal',
};

const ACTIVITY_LABEL = {
  sedentary:   'Tidak aktif',
  light:       'Ringan',
  moderate:    'Sedang',
  active:      'Aktif',
  very_active: 'Sangat aktif',
};

// Layout A4 (595 x 842 pt)
const MARGIN    = 40;
const CONTENT_W = 515;
const FOOTER_H  = 50;

// ─── Helper format ───────────────────────────────────────────────────────────
const num = (v) => {
  const n = parseFloat(v);
  return Number.isFinite(n) ? n : 0;
};

const fmt = (v, digits = 0) =>
  num(v).toLocaleString('id-ID', { minimumFractionDigits: digits, maximumFractionDigits: digits });

/** Kunci tanggal YYYY-MM-DD menurut zona waktu aplikasi (bukan UTC) */
const dateKey = (d) =>
  new Intl.DateTimeFormat('en-CA', { timeZone: TZ, year: 'numeric', month: '2-digit', day: '2-digit' })
    .format(new Date(d));

const fmtDate = (d, opts) => new Intl.DateTimeFormat('id-ID', { timeZone: TZ, ...opts }).format(new Date(d));

const conditionText = (raw) =>
  String(raw || 'none')
    .split(',')
    .map((c) => CONDITION_LABEL[c.trim()] || c.trim())
    .join(', ');

// ─── Helper layout ───────────────────────────────────────────────────────────
const bottomLimit = (doc) => doc.page.height - FOOTER_H - 10;

/** Pindah halaman jika sisa ruang kurang dari `h` */
const ensureSpace = (doc, h) => {
  if (doc.y + h > bottomLimit(doc)) {
    doc.addPage();
    doc.y = MARGIN;
  }
};

/** Potong teks agar muat di lebar `w` (font harus sudah di-set) */
const fit = (doc, text, w) => {
  let s = String(text ?? '');
  if (doc.widthOfString(s) <= w) return s;
  while (s.length > 0 && doc.widthOfString(`${s}...`) > w) s = s.slice(0, -1);
  return `${s}...`;
};

const drawHeader = (doc, { periodText, printedText }) => {
  const W = doc.page.width;
  doc.rect(0, 0, W, 96).fill(C.primary);

  doc.fillColor(C.white).font('Helvetica-Bold').fontSize(24).text('NutriScan', MARGIN, 26);
  doc.font('Helvetica').fontSize(11).fillColor('#E8F5E9')
    .text('Laporan Riwayat Makan & Nutrisi', MARGIN, 56);

  doc.font('Helvetica').fontSize(8.5).fillColor('#C8E6C9')
    .text('PERIODE', MARGIN, 28, { width: CONTENT_W, align: 'right' });
  doc.font('Helvetica-Bold').fontSize(10.5).fillColor(C.white)
    .text(periodText, MARGIN, 40, { width: CONTENT_W, align: 'right' });
  doc.font('Helvetica').fontSize(8.5).fillColor('#C8E6C9')
    .text(`Dicetak: ${printedText}`, MARGIN, 58, { width: CONTENT_W, align: 'right' });

  doc.y = 116;
};

const sectionTitle = (doc, title) => {
  ensureSpace(doc, 60);
  const y = doc.y;
  doc.rect(MARGIN, y + 1, 3, 13).fill(C.primary);
  doc.fillColor(C.text).font('Helvetica-Bold').fontSize(12.5).text(title, MARGIN + 10, y);
  doc.y = y + 22;
};

/** Kotak info berisi pasangan label/nilai dalam grid `cols` kolom */
const infoBox = (doc, items, cols = 2) => {
  const rowH  = 36;
  const colW  = CONTENT_W / cols;
  const nRows = Math.ceil(items.length / cols);
  const h     = nRows * rowH + 14;
  ensureSpace(doc, h);
  const y0 = doc.y;

  doc.roundedRect(MARGIN, y0, CONTENT_W, h, 6).fillAndStroke(C.zebra, C.border);

  items.forEach(({ label, value, color }, i) => {
    const cx = MARGIN + 14 + (i % cols) * colW;
    const cy = y0 + 10 + Math.floor(i / cols) * rowH;
    const w  = colW - 28;
    doc.fillColor(C.muted).font('Helvetica').fontSize(7.5).text(label.toUpperCase(), cx, cy, { width: w });
    doc.font('Helvetica-Bold').fontSize(10.5);
    doc.fillColor(color || C.text).text(fit(doc, value, w), cx, cy + 11, { width: w, lineBreak: false });
  });

  doc.y = y0 + h + 16;
};

/** Baris kartu statistik */
const statCards = (doc, cards) => {
  const gap = 10;
  const w   = (CONTENT_W - gap * (cards.length - 1)) / cards.length;
  const h   = 66;
  ensureSpace(doc, h);
  const y0 = doc.y;

  cards.forEach((c, i) => {
    const x    = MARGIN + i * (w + gap);
    const tone = c.tone || 'normal';
    const bg   = tone === 'bad' ? C.redLight : tone === 'warn' ? C.orangeLight : C.primaryLight;
    const fg   = tone === 'bad' ? C.red      : tone === 'warn' ? C.orange      : C.primary;

    doc.roundedRect(x, y0, w, h, 6).fill(bg);
    doc.fillColor(C.muted).font('Helvetica').fontSize(7.5).text(c.label.toUpperCase(), x + 10, y0 + 10, { width: w - 20 });
    doc.fillColor(fg).font('Helvetica-Bold').fontSize(16).text(c.value, x + 10, y0 + 23, { width: w - 20, lineBreak: false });
    if (c.sub) {
      doc.font('Helvetica').fontSize(7.5);
      doc.fillColor(C.muted).text(fit(doc, c.sub, w - 20), x + 10, y0 + 47, { width: w - 20, lineBreak: false });
    }
  });

  doc.y = y0 + h + 10;
};

/**
 * Tabel dengan header berulang di setiap halaman baru.
 * columns: [{ header, width, align }]
 * rows:    [{ cells: string[], fill?, colors?: (string|null)[], bold? }]
 */
const table = (doc, columns, rows) => {
  const headerH = 22;
  const rowH    = 19;
  const pad     = 6;

  const drawHead = () => {
    const y = doc.y;
    doc.rect(MARGIN, y, CONTENT_W, headerH).fill(C.primary);
    let x = MARGIN;
    doc.font('Helvetica-Bold').fontSize(8.5).fillColor(C.white);
    columns.forEach((c) => {
      doc.text(c.header, x + pad, y + 7, { width: c.width - pad * 2, align: c.align || 'left', lineBreak: false });
      x += c.width;
    });
    doc.y = y + headerH;
  };

  ensureSpace(doc, headerH + rowH * 2);
  drawHead();

  rows.forEach((row, i) => {
    if (doc.y + rowH > bottomLimit(doc)) {
      doc.addPage();
      doc.y = MARGIN;
      drawHead();
    }
    const y    = doc.y;
    const fill = row.fill || (i % 2 === 1 ? C.zebra : null);
    if (fill) doc.rect(MARGIN, y, CONTENT_W, rowH).fill(fill);

    let x = MARGIN;
    row.cells.forEach((cell, ci) => {
      const c = columns[ci];
      doc.font(row.bold ? 'Helvetica-Bold' : 'Helvetica').fontSize(8.5);
      doc.fillColor(row.colors?.[ci] || C.text)
        .text(fit(doc, cell, c.width - pad * 2), x + pad, y + 6, {
          width: c.width - pad * 2, align: c.align || 'left', lineBreak: false,
        });
      x += c.width;
    });

    doc.moveTo(MARGIN, y + rowH).lineTo(MARGIN + CONTENT_W, y + rowH)
      .lineWidth(0.5).strokeColor(C.border).stroke();
    doc.y = y + rowH;
  });

  doc.y += 16;
};

const emptyNote = (doc, text) => {
  ensureSpace(doc, 50);
  const y = doc.y;
  doc.roundedRect(MARGIN, y, CONTENT_W, 40, 6).fillAndStroke(C.zebra, C.border);
  doc.fillColor(C.muted).font('Helvetica-Oblique').fontSize(9.5)
    .text(text, MARGIN, y + 15, { width: CONTENT_W, align: 'center' });
  doc.y = y + 56;
};

/** Footer di semua halaman — panggil SETELAH seluruh konten selesai */
const drawFooters = (doc) => {
  const range = doc.bufferedPageRange();
  for (let i = range.start; i < range.start + range.count; i++) {
    doc.switchToPage(i);
    // Matikan margin bawah sementara agar menulis di area footer tidak memicu halaman baru
    const oldBottom = doc.page.margins.bottom;
    doc.page.margins.bottom = 0;

    const y = doc.page.height - FOOTER_H + 8;
    doc.moveTo(MARGIN, y).lineTo(MARGIN + CONTENT_W, y).lineWidth(0.5).strokeColor(C.border).stroke();
    doc.fillColor(C.muted).font('Helvetica').fontSize(7.5)
      .text(
        'Laporan ini dibuat otomatis oleh aplikasi NutriScan dan bukan pengganti saran medis. ' +
        'Konsultasikan dengan dokter atau ahli gizi.',
        MARGIN, y + 8, { width: CONTENT_W - 90, lineBreak: true }
      );
    doc.text(`Halaman ${i + 1} dari ${range.count}`, MARGIN, y + 8, { width: CONTENT_W, align: 'right' });

    doc.page.margins.bottom = oldBottom;
  }
};

// ─── Template utama ──────────────────────────────────────────────────────────
/**
 * @param {PDFKit.PDFDocument} doc  dokumen dengan opsi bufferPages: true
 * @param {object} data { user, profile, recommendation, logs, days }
 */
const renderMealReport = (doc, { user, profile, recommendation, logs, days }) => {
  const now   = new Date();
  const start = new Date(now.getTime() - (days - 1) * 24 * 60 * 60 * 1000);

  const target   = num(profile?.daily_calorie_target) || 2000;
  const maxSugar = num(recommendation?.max_sugar_g) || 50;

  // ── Agregasi per hari (menurut tanggal WIB) ──
  const dailyMap = new Map();
  for (const log of logs) {
    const key = dateKey(log.logged_at);
    if (!dailyMap.has(key)) {
      dailyMap.set(key, { date: log.logged_at, items: 0, cal: 0, carbs: 0, protein: 0, fat: 0, sugar: 0 });
    }
    const d = dailyMap.get(key);
    d.items   += 1;
    d.cal     += num(log.calories_consumed);
    d.carbs   += num(log.carbs_consumed);
    d.protein += num(log.protein_consumed);
    d.fat     += num(log.fat_consumed);
    d.sugar   += num(log.sugar_consumed);
  }
  const daily      = [...dailyMap.values()];
  const daysLogged = daily.length;
  const sum        = (k) => daily.reduce((s, d) => s + d[k], 0);
  const avg        = (k) => (daysLogged ? sum(k) / daysLogged : 0);
  const overDays   = daily.filter((d) => d.cal > target).length;
  const avgCalPct  = Math.round((avg('cal') / target) * 100);

  // 1. Header
  drawHeader(doc, {
    periodText:  `${fmtDate(start, { day: '2-digit', month: 'short', year: 'numeric' })} - ${fmtDate(now, { day: '2-digit', month: 'short', year: 'numeric' })} (${days} hari)`,
    printedText: fmtDate(now, { day: '2-digit', month: 'long', year: 'numeric', hour: '2-digit', minute: '2-digit' }) + ' WIB',
  });

  // 2. Data pengguna
  sectionTitle(doc, 'Data Pengguna');
  infoBox(doc, [
    { label: 'Nama',  value: user.name },
    { label: 'Email', value: user.email },
  ]);

  // 3. Profil kesehatan
  sectionTitle(doc, 'Profil Kesehatan');
  if (profile) {
    const bmi    = num(profile.bmi);
    const bmiCat = getBMICategory(bmi);
    const bp     = profile.blood_pressure_systolic
      ? `${profile.blood_pressure_systolic}${profile.blood_pressure_diastolic ? `/${profile.blood_pressure_diastolic}` : ''} mmHg`
      : '-';
    infoBox(doc, [
      { label: 'BMI',                 value: `${fmt(bmi, 1)} (${bmiCat.category})`, color: bmiCat.color },
      { label: 'Target kalori harian', value: `${fmt(target)} kkal` },
      { label: 'Berat / Tinggi',      value: `${fmt(profile.weight_kg, 1)} kg / ${fmt(profile.height_cm)} cm` },
      { label: 'Usia / Aktivitas',    value: `${profile.age} tahun / ${ACTIVITY_LABEL[profile.activity_level] || profile.activity_level}` },
      { label: 'Kondisi medis',       value: conditionText(profile.medical_condition) },
      { label: 'Gula darah puasa',    value: profile.blood_sugar_fasting ? `${fmt(profile.blood_sugar_fasting)} mg/dL` : '-' },
      { label: 'Tekanan darah',       value: bp },
      { label: 'Batas gula harian',   value: `${fmt(maxSugar)} g` },
    ]);
  } else {
    emptyNote(doc, 'Profil kesehatan belum diisi.');
  }

  // 4. Ringkasan
  sectionTitle(doc, 'Ringkasan Periode');
  if (daysLogged === 0) {
    emptyNote(doc, 'Belum ada catatan makan pada periode ini. Mulai catat makananmu di aplikasi NutriScan!');
  } else {
    statCards(doc, [
      {
        label: 'Rata-rata kalori/hari',
        value: `${fmt(avg('cal'))} kkal`,
        sub:   `${avgCalPct}% dari target ${fmt(target)} kkal`,
        tone:  avgCalPct > 100 ? 'bad' : avgCalPct >= 90 ? 'warn' : 'normal',
      },
      {
        label: 'Rata-rata gula/hari',
        value: `${fmt(avg('sugar'), 1)} g`,
        sub:   `Batas ${fmt(maxSugar)} g/hari`,
        tone:  avg('sugar') > maxSugar ? 'bad' : avg('sugar') >= maxSugar * 0.9 ? 'warn' : 'normal',
      },
      {
        label: 'Hari melebihi target',
        value: `${overDays} hari`,
        sub:   `dari ${daysLogged} hari tercatat`,
        tone:  overDays > 0 ? 'warn' : 'normal',
      },
      {
        label: 'Total makanan dicatat',
        value: `${logs.length}`,
        sub:   `dalam ${days} hari terakhir`,
      },
    ]);
    statCards(doc, [
      { label: 'Rata-rata karbohidrat', value: `${fmt(avg('carbs'), 1)} g`,   sub: 'per hari' },
      { label: 'Rata-rata protein',     value: `${fmt(avg('protein'), 1)} g`, sub: 'per hari' },
      { label: 'Rata-rata lemak',       value: `${fmt(avg('fat'), 1)} g`,     sub: 'per hari' },
      { label: 'Total kalori',          value: `${fmt(sum('cal'))} kkal`,     sub: 'seluruh periode' },
    ]);
    doc.y += 6;

    // 5. Ringkasan harian
    sectionTitle(doc, 'Ringkasan Harian');
    table(
      doc,
      [
        { header: 'Tanggal',     width: 105 },
        { header: 'Item',        width: 40, align: 'center' },
        { header: 'Kalori',      width: 70, align: 'right' },
        { header: '% Target',    width: 60, align: 'right' },
        { header: 'Karbo (g)',   width: 60, align: 'right' },
        { header: 'Protein (g)', width: 60, align: 'right' },
        { header: 'Lemak (g)',   width: 60, align: 'right' },
        { header: 'Gula (g)',    width: 60, align: 'right' },
      ],
      daily.map((d) => {
        const pct     = Math.round((d.cal / target) * 100);
        const over    = d.cal > target;
        const sugarHi = d.sugar > maxSugar;
        return {
          fill:   over ? C.redLight : null,
          colors: [null, null, null, over ? C.red : pct >= 90 ? C.orange : C.primary, null, null, null, sugarHi ? C.red : null],
          cells:  [
            fmtDate(d.date, { weekday: 'short', day: '2-digit', month: 'short', year: 'numeric' }),
            String(d.items),
            fmt(d.cal),
            `${pct}%`,
            fmt(d.carbs, 1),
            fmt(d.protein, 1),
            fmt(d.fat, 1),
            fmt(d.sugar, 1),
          ],
        };
      })
    );

    // Keterangan warna
    ensureSpace(doc, 20);
    const ly = doc.y - 8;
    doc.rect(MARGIN, ly, 9, 9).fill(C.redLight);
    doc.fillColor(C.muted).font('Helvetica').fontSize(7.5)
      .text('Baris merah = kalori melebihi target harian. Angka gula merah = melebihi batas gula harian.', MARGIN + 14, ly + 1);
    doc.y = ly + 26;

    // 6. Detail catatan makan
    sectionTitle(doc, 'Detail Catatan Makan');
    table(
      doc,
      [
        { header: 'Tanggal',    width: 72 },
        { header: 'Jam',        width: 38, align: 'center' },
        { header: 'Makanan',    width: 140 },
        { header: 'Waktu Makan', width: 70 },
        { header: 'Porsi',      width: 50, align: 'right' },
        { header: 'Kalori',     width: 55, align: 'right' },
        { header: 'Karbo',      width: 45, align: 'right' },
        { header: 'Gula',       width: 45, align: 'right' },
      ],
      logs.map((log) => ({
        cells: [
          fmtDate(log.logged_at, { day: '2-digit', month: 'short', year: '2-digit' }),
          fmtDate(log.logged_at, { hour: '2-digit', minute: '2-digit', hour12: false }),
          log.food_name || '-',
          MEAL_LABEL[log.meal_type] || log.meal_type,
          `${fmt(log.portion_g)} g`,
          `${fmt(log.calories_consumed)} kkal`,
          `${fmt(log.carbs_consumed, 1)} g`,
          `${fmt(log.sugar_consumed, 1)} g`,
        ],
      }))
    );
  }

  // 7. Footer semua halaman
  drawFooters(doc);
};

module.exports = { renderMealReport };
