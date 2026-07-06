// lib/features/profile/presentation/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _client = ApiClient();
  late TabController _tabCtrl;

  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _client.get(ApiConstants.me),
        _client.get(ApiConstants.healthProfile),
      ]);
      setState(() {
        _user = results[0].data['data'] as Map<String, dynamic>?;
        _profile = results[1].data['data'] as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'jwt_token');
    if (mounted) context.go('/login');
  }

  // ── Helper: parse apapun ke double lalu format ────────────
  String _toFixed(dynamic val, [int decimals = 0]) {
    if (val == null) return '-';
    return (double.tryParse(val.toString()) ?? 0).toStringAsFixed(decimals);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profil',
            onPressed: () =>
                context.push('/profile/edit').then((_) => _loadData()),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Data Diri'),
            Tab(text: 'Rekomendasi'),
            Tab(text: 'Olahraga'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildDataDiriTab(),
                _buildRekomendasiTab(),
                _buildOlahragaTab(),
              ],
            ),
    );
  }

  // ── Tab 1: Data Diri ──────────────────────────────────────
  Widget _buildDataDiriTab() {
    if (_profile == null) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.person_outline, size: 64, color: AppColors.border),
        const SizedBox(height: 16),
        const Text('Profil belum diisi',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () =>
              context.push('/profile/edit').then((_) => _loadData()),
          child: const Text('Isi Profil Sekarang'),
        ),
      ]));
    }

    final bmi = double.tryParse(_profile!['bmi']?.toString() ?? '0') ?? 0;
    final bmr = double.tryParse(_profile!['bmr']?.toString() ?? '0') ?? 0;
    final tdee =
        double.tryParse(_profile!['daily_calorie_target']?.toString() ?? '0') ??
            0;
    final bmiCat = _profile!['bmi_category']?.toString() ?? '-';
    final bmiColor = _hexColor(_profile!['bmi_color']?.toString() ?? '#4CAF50');
    final cond = _profile!['medical_condition']?.toString() ?? 'none';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Avatar & nama
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      (_user?['name'] as String? ?? 'U')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(_user?['name']?.toString() ?? '-',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600)),
                        Text(_user?['email']?.toString() ?? '-',
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        _ConditionBadges(conditions: cond),
                      ])),
                ]))),

        const SizedBox(height: 12),

        // BMI Card
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Indeks Massa Tubuh (BMI)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: Column(children: [
                        Text(bmi.toStringAsFixed(1),
                            style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                color: bmiColor)),
                        Text(bmiCat,
                            style: TextStyle(
                                color: bmiColor, fontWeight: FontWeight.w500)),
                      ])),
                      Container(width: 1, height: 60, color: AppColors.border),
                      Expanded(
                          child: Column(children: [
                        Text('${bmr.toInt()}',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        const Text('BMR (kkal/hari)',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                            textAlign: TextAlign.center),
                      ])),
                      Container(width: 1, height: 60, color: AppColors.border),
                      Expanded(
                          child: Column(children: [
                        Text('${tdee.toInt()}',
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        const Text('Target kalori',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                            textAlign: TextAlign.center),
                      ])),
                    ]),
                  ],
                ))),

        const SizedBox(height: 12),

        // Data fisik
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Data Fisik',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    _InfoRow('Berat Badan', '${_profile!['weight_kg']} kg'),
                    _InfoRow('Tinggi Badan', '${_profile!['height_cm']} cm'),
                    _InfoRow('Usia', '${_profile!['age']} tahun'),
                    _InfoRow('Jenis Kelamin',
                        _profile!['gender'] == 'male' ? 'Pria' : 'Wanita'),
                    _InfoRow(
                        'Aktivitas',
                        _activityLabel(
                            _profile!['activity_level']?.toString() ?? '')),
                    if (_profile!['blood_sugar_fasting'] != null)
                      _InfoRow('Gula Darah Puasa',
                          '${_profile!['blood_sugar_fasting']} mg/dL'),
                    if (_profile!['blood_pressure_systolic'] != null)
                      _InfoRow('Tekanan Darah',
                          '${_profile!['blood_pressure_systolic']} mmHg'),
                  ],
                ))),

        const SizedBox(height: 12),

        // Edit button
        OutlinedButton.icon(
          onPressed: () =>
              context.push('/profile/edit').then((_) => _loadData()),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit Data Profil'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: const BorderSide(color: AppColors.primary),
            foregroundColor: AppColors.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    );
  }

  // ── Tab 2: Rekomendasi Makanan ───────────────────────────
  Widget _buildRekomendasiTab() {
    final rec = _profile?['recommendation'] as Map<String, dynamic>?;
    if (rec == null) {
      return const Center(
          child: Text('Lengkapi profil untuk mendapatkan rekomendasi'));
    }

    final food = rec['food'] as Map<String, dynamic>? ?? {};
    final targets = rec['nutrition_targets'] as Map<String, dynamic>? ?? {};
    final allowed = List<String>.from(food['allowed_foods'] ?? []);
    final avoided = List<String>.from(food['avoided_foods'] ?? []);
    final firedRules = List<String>.from(rec['fired_rules'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Pola makan
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.restaurant_outlined,
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('Pola Makan yang Dianjurkan',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(food['meal_pattern']?.toString() ?? '-',
                          style: const TextStyle(fontSize: 13, height: 1.5)),
                    ),
                  ],
                ))),

        const SizedBox(height: 12),

        // Target nutrisi harian
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.track_changes, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('Target Nutrisi Harian',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 12),
                    // ✅ FIX: pakai _toFixed() agar aman meski API return String
                    _NutrientTarget(
                        'Kalori',
                        '${_toFixed(targets['daily_calories'])} kkal',
                        AppColors.primary),
                    _NutrientTarget(
                        'Max Gula',
                        '${_toFixed(targets['max_sugar_g'])} g',
                        AppColors.yellow),
                    _NutrientTarget(
                        'Max Natrium',
                        '${_toFixed(targets['max_sodium_mg'])} mg',
                        AppColors.red),
                    _NutrientTarget('Max Karbohidrat',
                        '${_toFixed(targets['max_carbs_g'])} g', Colors.blue),
                    _NutrientTarget(
                        'Min Protein',
                        '${_toFixed(targets['min_protein_g'])} g',
                        Colors.orange),
                    _NutrientTarget('Max Lemak',
                        '${_toFixed(targets['max_fat_g'])} g', Colors.purple),
                  ],
                ))),

        const SizedBox(height: 12),

        // Makanan dianjurkan
        _FoodListCard(
            title: 'Makanan Dianjurkan',
            items: allowed,
            color: AppColors.green,
            icon: Icons.check_circle_outline),
        const SizedBox(height: 12),

        // Makanan dihindari
        _FoodListCard(
            title: 'Makanan Dihindari',
            items: avoided,
            color: AppColors.red,
            icon: Icons.cancel_outlined),
        const SizedBox(height: 12),

        // Rule FC yang aktif (untuk transparansi sistem)
        if (firedRules.isNotEmpty)
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.psychology_outlined,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text('Rule Sistem Pakar Aktif',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ]),
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: firedRules
                              .map((r) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Text(r,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w500)),
                                  ))
                              .toList()),
                    ],
                  ))),

        const SizedBox(height: 20),
      ]),
    );
  }

  // ── Tab 3: Rekomendasi Olahraga ──────────────────────────
  Widget _buildOlahragaTab() {
    final rec = _profile?['recommendation'] as Map<String, dynamic>?;
    final exercise = rec?['exercise'] as Map<String, dynamic>?;

    if (exercise == null) {
      return const Center(
          child:
              Text('Lengkapi profil untuk mendapatkan rekomendasi olahraga'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.fitness_center,
                          color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('Rekomendasi Olahraga',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 16),
                    _ExerciseStat(Icons.sports_gymnastics, 'Jenis Olahraga',
                        exercise['exercise_type']?.toString() ?? '-'),
                    _ExerciseStat(Icons.timer_outlined, 'Durasi per Sesi',
                        '${exercise['exercise_duration_min'] ?? '-'} menit'),
                    _ExerciseStat(Icons.calendar_today, 'Frekuensi',
                        exercise['exercise_freq']?.toString() ?? '-'),
                  ],
                ))),
        const SizedBox(height: 12),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(children: [
                      Icon(Icons.warning_amber_outlined,
                          color: AppColors.yellow),
                      SizedBox(width: 8),
                      Text('Catatan Penting',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 10),
                    Text(exercise['exercise_notes']?.toString() ?? '-',
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: AppColors.textSecondary)),
                  ],
                ))),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.red.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.red.withOpacity(0.3)),
          ),
          child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppColors.red, size: 18),
                SizedBox(width: 10),
                Expanded(
                    child: Text(
                  'Rekomendasi olahraga ini bersifat informatif berdasarkan panduan PERKENI 2024. Konsultasikan dengan dokter sebelum memulai program olahraga baru.',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.red, height: 1.5),
                )),
              ]),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  // ── Helper widgets ────────────────────────────────────────
  Widget _InfoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
      );

  Widget _NutrientTarget(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary))),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: color, fontSize: 14)),
        ]),
      );

  Widget _ExerciseStat(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(children: [
          Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.primary, size: 22)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ])),
        ]),
      );

  String _activityLabel(String val) =>
      {
        'sedentary': 'Tidak aktif',
        'light': 'Ringan',
        'moderate': 'Sedang',
        'active': 'Aktif',
        'very_active': 'Sangat aktif',
      }[val] ??
      val;

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.green;
    }
  }
}

// ── Widget pembantu ───────────────────────────────────────────
class _ConditionBadges extends StatelessWidget {
  final String conditions;
  const _ConditionBadges({required this.conditions});

  @override
  Widget build(BuildContext context) {
    if (conditions == 'none') return const SizedBox();
    final list = conditions.split(',');
    final labels = {
      'diabetes': 'DM Tipe 2',
      'hypertension': 'Hipertensi',
      'cholesterol': 'Kolesterol',
      'kidney': 'Ginjal'
    };
    return Wrap(
        spacing: 4,
        children: list
            .map((c) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: AppColors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(labels[c.trim()] ?? c,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.red,
                          fontWeight: FontWeight.w500)),
                ))
            .toList());
  }
}

class _FoodListCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color color;
  final IconData icon;
  const _FoodListCard(
      {required this.title,
      required this.items,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 10),
                Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: items
                        .map((item) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: color.withOpacity(0.3)),
                              ),
                              child: Text(item,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: color,
                                      fontWeight: FontWeight.w500)),
                            ))
                        .toList()),
              ],
            )),
      );
}
