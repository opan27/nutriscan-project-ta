# NutriScan — Setup Guide

## Struktur Project
```
nutriscan-backend/   ← Express.js API
nutriscan-flutter/   ← Flutter Mobile App
```

---

## 1. Backend Setup (Express.js)

### Prasyarat
- Node.js >= 18
- MySQL 8.0+
- Python 3.8+ dengan ultralytics (`pip install ultralytics`)

### Langkah Setup

```bash
cd nutriscan-backend
npm install
```

**Buat file `.env`** (sudah ada template, tinggal isi password DB):
```
DB_PASSWORD=password_mysql_kamu
JWT_SECRET=ganti_dengan_string_acak_panjang
```

**Setup database:**
```bash
mysql -u root -p < database/schema.sql
```

**Taruh model YOLO:**
```
nutriscan-backend/yolo/best.pt   ← copy model kamu ke sini
```

**Jalankan server:**
```bash
npm run dev        # development (nodemon)
npm start          # production
```

Server berjalan di: `http://localhost:3000`
Test: `GET http://localhost:3000/api/ping`

---

## 2. Flutter Setup

### Prasyarat
- Flutter SDK >= 3.10
- Android Studio / VS Code
- Android Emulator atau device fisik

### Langkah Setup

```bash
cd nutriscan-flutter
flutter pub get
```

**Sesuaikan BASE URL** di `lib/core/constants/api_constants.dart`:
```dart
// Android Emulator
static const String baseUrl = 'http://10.0.2.2:3000/api';

// Device fisik (ganti dengan IP lokal PC kamu)
static const String baseUrl = 'http://192.168.x.x:3000/api';

// iOS Simulator
static const String baseUrl = 'http://localhost:3000/api';
```

**Generate file kode:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Jalankan app:**
```bash
flutter run
```

---

## 3. API Endpoints Lengkap

| Method | Endpoint | Deskripsi | Auth |
|--------|----------|-----------|------|
| POST | `/api/auth/register` | Daftar akun baru | ❌ |
| POST | `/api/auth/login` | Login, dapat token JWT | ❌ |
| GET  | `/api/auth/me` | Data user sendiri | ✅ |
| POST | `/api/scan` | Upload foto, deteksi makanan | ✅ |
| GET  | `/api/scan/history` | Riwayat scan | ✅ |
| POST | `/api/scan/:id/feedback` | Koreksi hasil deteksi | ✅ |
| GET  | `/api/food/search?q=sate` | Cari makanan | ✅ |
| GET  | `/api/food/:id` | Detail makanan | ✅ |
| POST | `/api/meal-log` | Catat makan | ✅ |
| GET  | `/api/meal-log/today` | Log hari ini + total | ✅ |
| DELETE | `/api/meal-log/:id` | Hapus log | ✅ |
| POST | `/api/health/profile` | Simpan profil kesehatan | ✅ |
| GET  | `/api/health/profile` | Ambil profil | ✅ |
| GET  | `/api/analytics/weekly` | Insight mingguan | ✅ |
| GET  | `/api/analytics/export-pdf` | Download laporan PDF | ✅ |
| GET  | `/api/reminder` | Daftar pengingat | ✅ |
| POST | `/api/reminder` | Tambah pengingat | ✅ |
| PUT  | `/api/reminder/:id/toggle` | Aktif/nonaktif | ✅ |
| DELETE | `/api/reminder/:id` | Hapus pengingat | ✅ |
| GET  | `/api/admin/foods` | Daftar semua makanan | ✅ Admin |
| POST | `/api/admin/foods` | Tambah makanan | ✅ Admin |
| PUT  | `/api/admin/foods/:id` | Update makanan | ✅ Admin |
| DELETE | `/api/admin/foods/:id` | Hapus makanan | ✅ Admin |
| GET  | `/api/admin/accuracy-stats` | Statistik akurasi YOLO | ✅ Admin |

---

## 4. Format Response API

Semua response mengikuti format:
```json
{
  "success": true,
  "message": "Pesan opsional",
  "data": { ... }
}
```

### Contoh: POST /api/scan
**Request:** multipart/form-data dengan field `image` (file) dan `portion_g` (opsional)

**Response:**
```json
{
  "success": true,
  "data": {
    "scan_id": 42,
    "detected_label": "sate_ayam",
    "food_name": "Sate Ayam",
    "confidence_pct": 97.5,
    "portion_g": 100,
    "nutrition": {
      "calories": 250, "carbohydrates": 10.5, "protein": 25.0,
      "fat": 12.0, "sugar": 3.5, "sodium": 380, "fiber": 0.5
    },
    "warning": {
      "level": "yellow",
      "label": "Batasi",
      "color": "#FFC107",
      "reasons": ["Kandungan natrium cukup tinggi, batasi konsumsinya"]
    }
  }
}
```

---

## 5. Cara Kerja YOLO Integration

```
Flutter upload foto
    ↓
Express: Multer simpan ke /uploads/
    ↓
yoloService.js: spawn Python detect.py
    ↓
detect.py: jalankan model YOLO → print JSON ke stdout
    ↓
Express: parse JSON → query tabel foods
    ↓
warningService.js: hitung warning berdasarkan kondisi medis
    ↓
Return response lengkap ke Flutter
```

Output `detect.py` ke stdout:
```json
{"label": "sate_ayam", "confidence": 0.975}
```

---

## 6. Menambah Admin

Untuk mengubah user menjadi admin, jalankan query MySQL:
```sql
UPDATE users SET role = 'admin' WHERE email = 'email@kamu.com';
```

---

## 7. Catatan untuk Skripsi

- **Akurasi YOLO**: Setiap scan tersimpan di `model_accuracy_logs`. User bisa koreksi lewat `POST /api/scan/:id/feedback`. Data ini jadi bahan statistik akurasi di lampiran skripsi.
- **Sistem Pakar**: Rule-based di `warningService.js` — mudah dijelaskan sebagai diagram pohon keputusan.
- **Export PDF**: `GET /api/analytics/export-pdf` menghasilkan laporan yang bisa ditunjukkan ke dokter.
