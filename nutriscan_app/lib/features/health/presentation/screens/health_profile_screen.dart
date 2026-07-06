// lib/features/health/presentation/screens/health_profile_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

class HealthProfileScreen extends StatefulWidget {
  const HealthProfileScreen({super.key});

  @override
  State<HealthProfileScreen> createState() => _HealthProfileScreenState();
}

class _HealthProfileScreenState extends State<HealthProfileScreen> {
  final _client = ApiClient();
  final _formKey = GlobalKey<FormState>();

  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();

  String _gender = 'male';
  String _activity = 'sedentary';
  Set<String> _conditions = {'none'};

  Map<String, dynamic>? _result;
  bool _loading = false;
  bool _fetching = true;

  final _activityLabels = const {
    'sedentary': 'Tidak aktif (duduk sepanjang hari)',
    'light': 'Ringan (olahraga 1-3x seminggu)',
    'moderate': 'Sedang (olahraga 3-5x seminggu)',
    'active': 'Aktif (olahraga 6-7x seminggu)',
    'very_active': 'Sangat aktif (atlet/kerja fisik berat)',
  };

  final _conditionLabels = const {
    'none': 'Tidak ada',
    'diabetes': 'Diabetes',
    'hypertension': 'Hipertensi',
    'cholesterol': 'Kolesterol',
    'kidney': 'Penyakit Ginjal',
  };

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final res = await _client.get(ApiConstants.healthProfile);
      final d = res.data['data'];
      _weightCtrl.text = '${d['weight_kg']}';
      _heightCtrl.text = '${d['height_cm']}';
      _ageCtrl.text = '${d['age']}';
      setState(() {
        _gender = d['gender'] ?? 'male';
        _activity = d['activity_level'] ?? 'sedentary';
        final raw = (d['medical_condition'] ?? 'none') as String;
        _conditions = raw.split(',').map((e) => e.trim()).toSet();
        _result = {
          'bmi': d['bmi'],
          'bmi_category': d['bmi_category'],
          'bmi_color': d['bmi_color'],
          'bmr': d['bmr'],
          'daily_calorie_target': d['daily_calorie_target'],
        };
      });
    } catch (_) {
      // Profil belum ada, form kosong
    } finally {
      setState(() => _fetching = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
    });

    final condStr = _conditions.contains('none')
        ? 'none'
        : _conditions.where((c) => c != 'none').join(',');

    try {
      final res = await _client.post(ApiConstants.healthProfile, data: {
        'weight_kg': double.parse(_weightCtrl.text),
        'height_cm': double.parse(_heightCtrl.text),
        'age': int.parse(_ageCtrl.text),
        'gender': _gender,
        'activity_level': _activity,
        'medical_condition': condStr,
      });
      setState(() => _result = res.data['data']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profil berhasil disimpan ✅'),
            backgroundColor: AppColors.primary));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Gagal menyimpan profil'),
            backgroundColor: AppColors.red));
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Kesehatan')),
      body: _fetching
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Hasil BMI/BMR ──────────────────────────────────────
                    if (_result != null) _buildResultCard(),
                    const SizedBox(height: 20),

                    // ─── Data Fisik ─────────────────────────────────────────
                    _sectionTitle('Data Fisik'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: TextFormField(
                        controller: _weightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Berat Badan', suffixText: 'kg'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: TextFormField(
                        controller: _heightCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Tinggi Badan', suffixText: 'cm'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      )),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                          child: TextFormField(
                        controller: _ageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Usia', suffixText: 'tahun'),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      )),
                      const SizedBox(width: 12),
                      // Gender toggle
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Jenis Kelamin',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          Row(children: [
                            _GenderBtn(
                                label: 'Pria',
                                value: 'male',
                                selected: _gender,
                                onTap: (v) => setState(() => _gender = v)),
                            const SizedBox(width: 8),
                            _GenderBtn(
                                label: 'Wanita',
                                value: 'female',
                                selected: _gender,
                                onTap: (v) => setState(() => _gender = v)),
                          ]),
                        ],
                      )),
                    ]),

                    const SizedBox(height: 20),
                    _sectionTitle('Tingkat Aktivitas'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _activity,
                      decoration:
                          const InputDecoration(labelText: 'Pilih aktivitas'),
                      items: _activityLabels.entries
                          .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value,
                                  style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => setState(() => _activity = v!),
                    ),

                    const SizedBox(height: 20),
                    _sectionTitle('Kondisi Medis'),
                    const SizedBox(height: 4),
                    const Text('Pilih semua yang berlaku',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _conditionLabels.entries.map((e) {
                        final selected = _conditions.contains(e.key);
                        return FilterChip(
                          label: Text(e.value),
                          selected: selected,
                          selectedColor: AppColors.primary.withOpacity(0.15),
                          checkmarkColor: AppColors.primary,
                          onSelected: (v) => setState(() {
                            if (e.key == 'none') {
                              _conditions = {'none'};
                            } else {
                              _conditions.remove('none');
                              v
                                  ? _conditions.add(e.key)
                                  : _conditions.remove(e.key);
                              if (_conditions.isEmpty) _conditions.add('none');
                            }
                          }),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Simpan Profil'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildResultCard() {
    double p(dynamic v) => v == null
        ? 0
        : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);
    final bmi = p(_result!['bmi']);
    final bmr = p(_result!['bmr']);
    final tdee = p(_result!['daily_calorie_target']);
    final cat = _result!['bmi_category'] ?? '-';
    final color = _hexColor(_result!['bmi_color'] ?? '#4CAF50');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.primary.withOpacity(0.02)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(children: [
        Expanded(child: _ResultTile('BMI', bmi.toStringAsFixed(1), cat, color)),
        const VerticalDivider(),
        Expanded(
            child: _ResultTile('BMR', '${bmr.toInt()} kkal', 'kebutuhan dasar',
                AppColors.textSecondary)),
        const VerticalDivider(),
        Expanded(
            child: _ResultTile('TDEE', '${tdee.toInt()} kkal', 'target/hari',
                AppColors.primary)),
      ]),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600));

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.green;
    }
  }
}

class _ResultTile extends StatelessWidget {
  final String title, value, sub;
  final Color color;
  const _ResultTile(this.title, this.value, this.sub, this.color);

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(title,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 17, color: color)),
        Text(sub,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ]);
}

class _GenderBtn extends StatelessWidget {
  final String label, value, selected;
  final void Function(String) onTap;
  const _GenderBtn(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            )),
      ),
    );
  }
}
