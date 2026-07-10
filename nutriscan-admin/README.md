# NutriScan Admin Dashboard

Dashboard admin berbasis **React + Vite** untuk aplikasi NutriScan. Terpisah dari
app mobile Flutter, ditujukan untuk layar desktop.

## Fitur
- 🔐 **Login admin** — hanya akun dengan `role = 'admin'` yang bisa masuk
- 📊 **Dashboard** — kartu statistik (total user, makanan, scan, akurasi) + grafik tren scan & makanan terpopuler
- 🍽️ **Manajemen Makanan** — CRUD database nutrisi (tambah/edit/hapus + pencarian)
- 📈 **Statistik Akurasi** — evaluasi model YOLO (benar vs salah, per-label) untuk lampiran skripsi
- 👥 **Manajemen User** — lihat user, jadikan/turunkan admin, hapus akun

## Menjalankan

Pastikan **backend Express jalan di `http://localhost:3000`** dan MySQL aktif.

```bash
cd nutriscan-admin
npm install
npm run dev
```

Buka `http://localhost:5173`. Request `/api` otomatis di-proxy ke `localhost:3000`
(lihat `vite.config.js`).

## Membuat akun admin

Register lewat app / API, lalu promosikan via MySQL:

```sql
UPDATE users SET role = 'admin' WHERE email = 'email@kamu.com';
```

## Build produksi

```bash
npm run build      # output ke folder dist/
```

Saat deploy terpisah dari backend, set base URL API lewat env `VITE_API_BASE`
(mis. `VITE_API_BASE=https://api.nutriscan.com`).

## Struktur
```
src/
├── api/client.js          # axios + interceptor token/401
├── auth/AuthContext.jsx   # state login, guard role admin
├── components/            # Layout, Modal, StatCard, PageHeader, ProtectedRoute
└── pages/                 # Login, Dashboard, Foods, Accuracy, Users
```

## Endpoint backend yang dipakai
| Method | Endpoint | Halaman |
|--------|----------|---------|
| GET | `/api/admin/stats` | Dashboard |
| GET/POST/PUT/DELETE | `/api/admin/foods` | Manajemen Makanan |
| GET | `/api/admin/accuracy-stats` | Statistik Akurasi |
| GET | `/api/admin/users` | Manajemen User |
| PUT | `/api/admin/users/:id/role` | Manajemen User |
| DELETE | `/api/admin/users/:id` | Manajemen User |
