// lib/features/profile/presentation/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _client = ApiClient();
  final _formKey = GlobalKey<FormState>();

  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _sugarCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();

  String _gender = 'male';
  String _activity = 'sedentary';
  Set<String> _conditions = {};
  bool _loading = false;
  bool _fetching = true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    _sugarCtrl.dispose();
    _bpCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final res = await _client.get(ApiConstants.healthProfile);
      final d = res.data['data'] as Map<String, dynamic>? ?? {};
      _weightCtrl.text = d['weight_kg']?.toString() ?? '';
      _heightCtrl.text = d['height_cm']?.toString() ?? '';
      _ageCtrl.text = d['age']?.toString() ?? '';
      _sugarCtrl.text = d['blood_sugar_fasting']?.toString() ?? '';
      _bpCtrl.text = d['blood_pressure_systolic']?.toString() ?? '';
      setState(() {
        _gender = d['gender']?.toString() ?? 'male';
        _activity = d['activity_level']?.toString() ?? 'sedentary';
        final raw = (d['medical_condition']?.toString() ?? 'none');
        _conditions =
            raw == 'none' ? {} : raw.split(',').map((e) => e.trim()).toSet();
        _fetching = false;
      });
    } catch (_) {
      setState(() => _fetching = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final condStr = _conditions.isEmpty ? 'none' : _conditions.join(',');
    try {
      await _client.post(ApiConstants.healthProfile, data: {
        'weight_kg': double.tryParse(_weightCtrl.text),
        'height_cm': double.tryParse(_heightCtrl.text),
        'age': int.tryParse(_ageCtrl.text),
        'gender': _gender,
        'activity_level': _activity,
        'medical_condition': condStr,
        'blood_sugar_fasting': _sugarCtrl.text.isNotEmpty
            ? double.tryParse(_sugarCtrl.text)
            : null,
        'blood_pressure_systolic':
            _bpCtrl.text.isNotEmpty ? int.tryParse(_bpCtrl.text) : null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profil diperbarui! Rekomendasi disesuaikan.'),
              backgroundColor: AppColors.primary),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.red),
        );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: _fetching
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _sectionTitle('Data Fisik'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: TextFormField(
                      controller: _weightCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Berat Badan', suffixText: 'kg'),
                      validator: (v) =>
                          (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
                    )),
                    const SizedBox(width: 12),
                    Expanded(
                        child: TextFormField(
                      controller: _heightCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Tinggi Badan', suffixText: 'cm'),
                      validator: (v) =>
                          (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
                    )),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Usia', suffixText: 'tahun'),
                    validator: (v) =>
                        (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  const Text('Jenis Kelamin',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _GenderBtn('Pria', 'male'),
                    const SizedBox(width: 10),
                    _GenderBtn('Wanita', 'female'),
                  ]),
                  const SizedBox(height: 20),
                  _sectionTitle('Tingkat Aktivitas'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _activity,
                    decoration: const InputDecoration(
                        labelText: 'Pilih aktivitas harian'),
                    items: const [
                      DropdownMenuItem(
                          value: 'sedentary',
                          child: Text('Tidak aktif (kerja duduk)')),
                      DropdownMenuItem(
                          value: 'light',
                          child: Text('Ringan (olahraga 1–3x/minggu)')),
                      DropdownMenuItem(
                          value: 'moderate',
                          child: Text('Sedang (olahraga 3–5x/minggu)')),
                      DropdownMenuItem(
                          value: 'active',
                          child: Text('Aktif (olahraga 6–7x/minggu)')),
                      DropdownMenuItem(
                          value: 'very_active',
                          child: Text('Sangat aktif (atlet/kerja fisik)')),
                    ],
                    onChanged: (v) => setState(() => _activity = v!),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Kondisi Medis'),
                  const SizedBox(height: 4),
                  const Text('Pilih semua yang berlaku',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _ConditionChip('Diabetes Melitus Tipe 2', 'diabetes'),
                    _ConditionChip('Hipertensi', 'hypertension'),
                    _ConditionChip('Kolesterol', 'cholesterol'),
                    _ConditionChip('Penyakit Ginjal', 'kidney'),
                  ]),
                  const SizedBox(height: 20),
                  _sectionTitle('Data Kesehatan (Opsional)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _sugarCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Gula darah puasa terakhir',
                      suffixText: 'mg/dL',
                      hintText: 'contoh: 126',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tekanan darah sistolik terakhir',
                      suffixText: 'mmHg',
                      hintText: 'contoh: 140',
                    ),
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
                        : const Text('Simpan & Perbarui Rekomendasi'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600));

  Widget _GenderBtn(String label, String value) {
    final active = _gender == value;
    return Expanded(
        child: GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
      ),
    ));
  }

  Widget _ConditionChip(String label, String value) {
    final selected = _conditions.contains(value);
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary.withOpacity(0.15),
      checkmarkColor: AppColors.primary,
      onSelected: (v) => setState(() {
        if (v)
          _conditions.add(value);
        else
          _conditions.remove(value);
      }),
    );
  }
}
