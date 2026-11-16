// lib/features/onboarding/presentation/screens/onboarding_screen.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/health_validators.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _client = ApiClient();
  final _pageCtrl = PageController();
  int _currentPage = 0;
  bool _saving = false;

  // Data yang dikumpulkan
  double? _weight;
  double? _height;
  int? _age;
  String _gender = 'male';
  String _activity = 'sedentary';
  final Set<String> _conditions = {};
  double? _bloodSugar;
  int? _bpSystolic;

  // Controllers
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();

  final _totalPages = 8;

  // Index halaman (dipakai untuk loncat ke halaman yang salah)
  static const _pageWeight = 1;
  static const _pageHeight = 2;
  static const _pageAge = 3;
  static const _pageHealthData = 7;

  // ── Parsing & validasi: lihat core/utils/health_validators.dart ──
  static double? _parseNum(String v) => HealthValidators.parseNum(v);
  static String? _weightError(String v) => HealthValidators.weight(v);
  static String? _heightError(String v) => HealthValidators.height(v);
  static String? _ageError(String v) => HealthValidators.age(v);
  static String? _sugarError(String v) => HealthValidators.bloodSugar(v);
  static String? _bpError(String v) => HealthValidators.systolic(v);

  @override
  void dispose() {
    _pageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    _sugarCtrl.dispose();
    _bpCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _saveAndFinish();
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageCtrl.previousPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  void _goToPage(int page) {
    _pageCtrl.animateToPage(page,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  Future<void> _saveAndFinish() async {
    // Cek ulang semua data wajib sebelum kirim; kalau ada yang salah, buka halamannya
    final checks = <int, String?>{
      _pageWeight: _weight == null ? 'Berat badan wajib diisi' : _weightError(_weightCtrl.text),
      _pageHeight: _height == null ? 'Tinggi badan wajib diisi' : _heightError(_heightCtrl.text),
      _pageAge: _age == null ? 'Usia wajib diisi' : _ageError(_ageCtrl.text),
      _pageHealthData: _sugarError(_sugarCtrl.text) ?? _bpError(_bpCtrl.text),
    };
    for (final entry in checks.entries) {
      if (entry.value != null) {
        _showError(entry.value!);
        _goToPage(entry.key);
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await _client.post(ApiConstants.healthProfile, data: {
        'weight_kg': _weight,
        'height_cm': _height,
        'age': _age,
        'gender': _gender,
        'activity_level': _activity,
        'medical_condition':
            _conditions.isEmpty ? 'none' : _conditions.join(','),
        'blood_sugar_fasting': _bloodSugar,
        'blood_pressure_systolic': _bpSystolic,
      });
      if (mounted) context.go('/home');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError(ApiClient.errorMessage(e, 'Gagal menyimpan data. Coba lagi.'));
      // Server memberi tahu field mana yang salah → buka halamannya
      final data = e.response?.data;
      final field = data is Map ? data['field'] : null;
      const fieldToPage = {
        'weight_kg': _pageWeight,
        'height_cm': _pageHeight,
        'age': _pageAge,
        'gender': 4,
        'activity_level': 5,
        'medical_condition': 6,
        'blood_sugar_fasting': _pageHealthData,
        'blood_pressure_systolic': _pageHealthData,
      };
      if (fieldToPage[field] != null) _goToPage(fieldToPage[field]!);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('Gagal menyimpan data. Coba lagi.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ));
  }

  bool _canNext() {
    switch (_currentPage) {
      case _pageWeight:
        return _weight != null && _weightError(_weightCtrl.text) == null;
      case _pageHeight:
        return _height != null && _heightError(_heightCtrl.text) == null;
      case _pageAge:
        return _age != null && _ageError(_ageCtrl.text) == null;
      case _pageHealthData:
        return _sugarError(_sugarCtrl.text) == null &&
            _bpError(_bpCtrl.text) == null;
      default:
        return true;
    }
  }

  /// Input angka saja (boleh titik/koma untuk desimal)
  static final _decimalFormatter =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress bar & step ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        GestureDetector(
                          onTap: _back,
                          child: const Icon(Icons.arrow_back_ios,
                              size: 20, color: AppColors.textSecondary),
                        )
                      else
                        const SizedBox(width: 20),
                      Text('${_currentPage + 1} / $_totalPages',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      const SizedBox(width: 20),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / _totalPages,
                      minHeight: 6,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),

            // ── Pages ────────────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildWelcomePage(),
                  _buildWeightPage(),
                  _buildHeightPage(),
                  _buildAgePage(),
                  _buildGenderPage(),
                  _buildActivityPage(),
                  _buildConditionPage(),
                  _buildHealthDataPage(),
                ],
              ),
            ),

            // ── Tombol Next / Selesai ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: ElevatedButton(
                onPressed: (_canNext() && !_saving) ? _next : null,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : Text(_currentPage == _totalPages - 1
                        ? 'Selesai & Lihat Rekomendasi'
                        : 'Lanjut'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Halaman 0: Welcome ─────────────────────────────────────
  Widget _buildWelcomePage() => _PageWrapper(
        emoji: '👋',
        title: 'Halo! Selamat datang di NutriScan',
        subtitle:
            'Kami akan membantumu memantau nutrisi harian dan memberikan panduan makan & olahraga yang sesuai kondisi kesehatanmu.\n\nYuk, isi data diri kamu terlebih dahulu!',
        child: const SizedBox(),
      );

  // ── Halaman 1: Berat Badan ─────────────────────────────────
  Widget _buildWeightPage() => _PageWrapper(
        emoji: '⚖️',
        title: 'Berapa berat badanmu?',
        subtitle:
            'Data ini digunakan untuk menghitung BMI dan kebutuhan kalori harianmu.',
        child: Column(children: [
          TextField(
            controller: _weightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimalFormatter],
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.primary),
            decoration: InputDecoration(
              hintText: '65',
              hintStyle: const TextStyle(fontSize: 36, color: AppColors.border),
              suffixText: 'kg',
              suffixStyle:
                  const TextStyle(fontSize: 20, color: AppColors.textSecondary),
              border: InputBorder.none,
              helperText: 'Rentang 10–500 kg',
              errorText: _weightError(_weightCtrl.text),
              errorMaxLines: 2,
            ),
            onChanged: (v) => setState(() => _weight = _parseNum(v)),
          ),
        ]),
      );

  // ── Halaman 2: Tinggi Badan ────────────────────────────────
  Widget _buildHeightPage() => _PageWrapper(
        emoji: '📏',
        title: 'Berapa tinggi badanmu?',
        subtitle:
            'Tinggi badan digunakan bersama berat badan untuk menghitung BMI (Indeks Massa Tubuh).',
        child: TextField(
          controller: _heightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [_decimalFormatter],
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.primary),
          decoration: InputDecoration(
            hintText: '165',
            hintStyle: const TextStyle(fontSize: 36, color: AppColors.border),
            suffixText: 'cm',
            suffixStyle:
                const TextStyle(fontSize: 20, color: AppColors.textSecondary),
            border: InputBorder.none,
            helperText: 'Dalam sentimeter, rentang 50–300 cm',
            errorText: _heightError(_heightCtrl.text),
            errorMaxLines: 2,
          ),
          onChanged: (v) => setState(() => _height = _parseNum(v)),
        ),
      );

  // ── Halaman 3: Usia ────────────────────────────────────────
  Widget _buildAgePage() => _PageWrapper(
        emoji: '🎂',
        title: 'Berapa usiamu?',
        subtitle:
            'Usia mempengaruhi perhitungan kebutuhan kalori harianmu (BMR).',
        child: TextField(
          controller: _ageCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.primary),
          decoration: InputDecoration(
            hintText: '45',
            hintStyle: const TextStyle(fontSize: 36, color: AppColors.border),
            suffixText: 'tahun',
            suffixStyle:
                const TextStyle(fontSize: 20, color: AppColors.textSecondary),
            border: InputBorder.none,
            helperText: 'Rentang 1–120 tahun',
            errorText: _ageError(_ageCtrl.text),
            errorMaxLines: 2,
          ),
          onChanged: (v) => setState(() => _age = int.tryParse(v.trim())),
        ),
      );

  // ── Halaman 4: Jenis Kelamin ───────────────────────────────
  Widget _buildGenderPage() => _PageWrapper(
        emoji: '🧑',
        title: 'Jenis kelaminmu?',
        subtitle:
            'Jenis kelamin mempengaruhi rumus perhitungan BMR (kebutuhan kalori dasar).',
        child: Row(children: [
          _OptionCard(
            label: 'Pria',
            emoji: '👨',
            selected: _gender == 'male',
            onTap: () => setState(() => _gender = 'male'),
          ),
          const SizedBox(width: 16),
          _OptionCard(
            label: 'Wanita',
            emoji: '👩',
            selected: _gender == 'female',
            onTap: () => setState(() => _gender = 'female'),
          ),
        ]),
      );

  // ── Halaman 5: Tingkat Aktivitas ───────────────────────────
  Widget _buildActivityPage() => _PageWrapper(
        emoji: '🏃',
        title: 'Seberapa aktif keseharianmu?',
        subtitle: 'Ini menentukan total kebutuhan kalori harianmu (TDEE).',
        child: Column(
          children: [
            _ActivityOption('Tidak aktif', 'Kerja duduk, hampir tidak olahraga',
                'sedentary'),
            _ActivityOption(
                'Ringan', 'Olahraga ringan 1–3x per minggu', 'light'),
            _ActivityOption(
                'Sedang', 'Olahraga sedang 3–5x per minggu', 'moderate'),
            _ActivityOption(
                'Aktif', 'Olahraga berat 6–7x per minggu', 'active'),
            _ActivityOption(
                'Sangat aktif', 'Kerja fisik berat / atlet', 'very_active'),
          ].map((w) => w).toList(),
        ),
      );

  Widget _ActivityOption(String label, String sub, String value) =>
      GestureDetector(
        onTap: () => setState(() => _activity = value),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _activity == value
                ? AppColors.primary.withOpacity(0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _activity == value ? AppColors.primary : AppColors.border,
              width: _activity == value ? 2 : 0.8,
            ),
          ),
          child: Row(children: [
            Icon(
                _activity == value
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color:
                    _activity == value ? AppColors.primary : AppColors.border,
                size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: _activity == value
                              ? AppColors.primary
                              : AppColors.textPrimary)),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ])),
          ]),
        ),
      );

  // ── Halaman 6: Kondisi Medis ───────────────────────────────
  Widget _buildConditionPage() => _PageWrapper(
        emoji: '🏥',
        title: 'Kondisi kesehatan kamu?',
        subtitle:
            'Sistem pakar kami akan menyesuaikan rekomendasi berdasarkan kondisi medismu. Pilih semua yang berlaku.',
        child: Column(children: [
          _ConditionOption('Diabetes Melitus Tipe 2', 'diabetes', '💉'),
          _ConditionOption('Hipertensi', 'hypertension', '❤️'),
          _ConditionOption('Kolesterol Tinggi', 'cholesterol', '🩸'),
          _ConditionOption('Penyakit Ginjal', 'kidney', '🫘'),
          GestureDetector(
            onTap: () => setState(() => _conditions.clear()),
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _conditions.isEmpty
                    ? AppColors.primary.withOpacity(0.08)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _conditions.isEmpty
                      ? AppColors.primary
                      : AppColors.border,
                  width: _conditions.isEmpty ? 2 : 0.8,
                ),
              ),
              child: Row(children: [
                Icon(
                    _conditions.isEmpty
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: _conditions.isEmpty
                        ? AppColors.primary
                        : AppColors.border,
                    size: 20),
                const SizedBox(width: 12),
                const Text('Tidak ada kondisi medis khusus',
                    style: TextStyle(fontWeight: FontWeight.w500)),
              ]),
            ),
          ),
        ]),
      );

  Widget _ConditionOption(String label, String value, String emoji) =>
      GestureDetector(
        onTap: () => setState(() {
          if (_conditions.contains(value))
            _conditions.remove(value);
          else
            _conditions.add(value);
        }),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _conditions.contains(value)
                ? AppColors.primary.withOpacity(0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _conditions.contains(value)
                  ? AppColors.primary
                  : AppColors.border,
              width: _conditions.contains(value) ? 2 : 0.8,
            ),
          ),
          child: Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: _conditions.contains(value)
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ))),
            if (_conditions.contains(value))
              const Icon(Icons.check_circle,
                  color: AppColors.primary, size: 20),
          ]),
        ),
      );

  // ── Halaman 7: Data Kesehatan Opsional ─────────────────────
  Widget _buildHealthDataPage() => _PageWrapper(
        emoji: '📊',
        title: 'Data kesehatan tambahan',
        subtitle:
            'Opsional — tapi sangat membantu sistem memberikan rekomendasi yang lebih akurat.',
        child: Column(children: [
          TextField(
            controller: _sugarCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [_decimalFormatter],
            decoration: InputDecoration(
              labelText: 'Gula darah puasa terakhir',
              suffixText: 'mg/dL',
              hintText: 'contoh: 126',
              prefixIcon: const Icon(Icons.water_drop_outlined),
              errorText: _sugarError(_sugarCtrl.text),
              errorMaxLines: 2,
            ),
            onChanged: (v) => setState(() => _bloodSugar =
                v.trim().isEmpty ? null : _parseNum(v)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _bpCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Tekanan darah sistolik terakhir',
              suffixText: 'mmHg',
              hintText: 'contoh: 140',
              prefixIcon: const Icon(Icons.favorite_outline),
              errorText: _bpError(_bpCtrl.text),
              errorMaxLines: 2,
            ),
            onChanged: (v) => setState(() => _bpSystolic =
                v.trim().isEmpty ? null : int.tryParse(v.trim())),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              SizedBox(width: 10),
              Expanded(
                  child: Text(
                'Kalau tidak tahu, lewati saja. Kamu bisa isi nanti di halaman Profil.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              )),
            ]),
          ),
        ]),
      );
}

// ── Widget pembantu: Wrapper tiap halaman ──────────────────────
class _PageWrapper extends StatelessWidget {
  final String emoji, title, subtitle;
  final Widget child;
  const _PageWrapper(
      {required this.emoji,
      required this.title,
      required this.subtitle,
      required this.child});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 10),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
            const SizedBox(height: 32),
            child,
          ],
        ),
      );
}

// ── Widget pembantu: Option card ──────────────────────────────
class _OptionCard extends StatelessWidget {
  final String label, emoji;
  final bool selected;
  final VoidCallback onTap;
  const _OptionCard(
      {required this.label,
      required this.emoji,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 2.5 : 0.8,
              ),
            ),
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? AppColors.primary : AppColors.textPrimary,
                  )),
            ]),
          ),
        ),
      );
}
