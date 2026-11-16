// lib/core/utils/health_validators.dart
// Validasi data profil kesehatan — rentangnya SAMA dengan backend
// (nutriscan-backend/src/controllers/healthController.js). Kalau diubah, ubah keduanya.

class HealthValidators {
  HealthValidators._();

  /// Terima koma atau titik sebagai desimal: "65,5" → 65.5
  static double? parseNum(String? v) =>
      v == null ? null : double.tryParse(v.trim().replaceAll(',', '.'));

  static int? parseInt(String? v) => v == null ? null : int.tryParse(v.trim());

  /// [required] true → teks kosong dianggap error ("wajib diisi").
  /// false → kosong dianggap belum diisi (tidak tampil error).
  static String? weight(String? v, {bool required = false}) {
    if (v == null || v.trim().isEmpty) return required ? 'Berat badan wajib diisi' : null;
    final n = parseNum(v);
    if (n == null) return 'Masukkan angka yang valid';
    if (n < 10 || n > 500) return 'Berat badan harus antara 10–500 kg';
    return null;
  }

  static String? height(String? v, {bool required = false}) {
    if (v == null || v.trim().isEmpty) return required ? 'Tinggi badan wajib diisi' : null;
    final n = parseNum(v);
    if (n == null) return 'Masukkan angka yang valid';
    if (n > 0 && n < 3) return 'Isi dalam cm, bukan meter (mis. 165)';
    if (n < 50 || n > 300) return 'Tinggi badan harus antara 50–300 cm';
    return null;
  }

  static String? age(String? v, {bool required = false}) {
    if (v == null || v.trim().isEmpty) return required ? 'Usia wajib diisi' : null;
    final n = parseInt(v);
    if (n == null) return 'Masukkan usia dalam angka bulat';
    if (n < 1 || n > 120) return 'Usia harus antara 1–120 tahun';
    return null;
  }

  /// Opsional: kosong selalu valid
  static String? bloodSugar(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = parseNum(v);
    if (n == null) return 'Masukkan angka yang valid';
    if (n < 20 || n > 600) return 'Gula darah puasa harus antara 20–600 mg/dL';
    return null;
  }

  /// Opsional: kosong selalu valid
  static String? systolic(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = parseInt(v);
    if (n == null) return 'Masukkan angka bulat (mis. 120)';
    if (n < 50 || n > 300) return 'Tekanan sistolik harus antara 50–300 mmHg';
    return null;
  }
}
