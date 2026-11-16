// lib/features/meal_log/presentation/screens/meal_log_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

class MealLogScreen extends StatefulWidget {
  const MealLogScreen({super.key});

  @override
  State<MealLogScreen> createState() => _MealLogScreenState();
}

class _MealLogScreenState extends State<MealLogScreen> {
  final _client = ApiClient();
  Map<String, dynamic>? _todayData;
  bool _loading = true;

  final _mealLabels = const {
    'breakfast': ('Sarapan', Icons.wb_sunny_outlined),
    'lunch': ('Makan Siang', Icons.wb_cloudy_outlined),
    'dinner': ('Makan Malam', Icons.nights_stay_outlined),
    'snack': ('Camilan', Icons.cookie_outlined),
  };

  @override
  void initState() {
    super.initState();
    _loadToday();
  }

  Future<void> _loadToday() async {
    setState(() => _loading = true);
    try {
      final res = await _client.get(ApiConstants.mealLogToday);
      if (!mounted) return;
      setState(() {
        _todayData = res.data['data'];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError(ApiClient.errorMessage(e, 'Gagal memuat log makan'));
    }
  }

  Future<void> _deleteLog(int id) async {
    try {
      await _client.delete('${ApiConstants.mealLog}/$id');
    } catch (e) {
      if (mounted) _showError(ApiClient.errorMessage(e, 'Gagal menghapus log'));
    }
    if (mounted) _loadToday();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.red),
    );
  }

  Future<void> _showAddDialog() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddMealSheet(onAdded: () {}),
    );
    if (result == true) _loadToday();
  }

  @override
  Widget build(BuildContext context) {
    final total = _todayData?['total_today'] as Map<String, dynamic>?;
    double p(dynamic v, [double fb = 0]) => v == null
        ? fb
        : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? fb);
    final calTarget = p(_todayData?['calorie_target'], 2000);
    final calConsumed = p(total?['calories']);
    final calPct = (calConsumed / calTarget).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Makan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadToday,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadToday,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Progress kalori
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Kalori',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                  '${calConsumed.toInt()} / ${calTarget.toInt()} kkal',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13)),
                            ]),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: calPct,
                            minHeight: 10,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation(calPct > 0.9
                                ? AppColors.red
                                : AppColors.primary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Macro row
                        Row(children: [
                          _MacroPill('Karbo', '${p(total?['carbs']).toInt()}g',
                              Colors.blue),
                          _MacroPill(
                              'Protein',
                              '${p(total?['protein']).toInt()}g',
                              Colors.orange),
                          _MacroPill('Lemak', '${p(total?['fat']).toInt()}g',
                              Colors.purple),
                          _MacroPill('Gula', '${p(total?['sugar']).toInt()}g',
                              AppColors.yellow),
                        ]),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Per meal type sections
                  ..._mealLabels.entries.map((e) {
                    final key = e.key;
                    final label = e.value.$1;
                    final icon = e.value.$2;
                    final logs = List<Map<String, dynamic>>.from(
                        (_todayData?['logs']?[key] as List?) ?? []);

                    return _MealSection(
                      label: label,
                      icon: icon,
                      logs: logs,
                      onDelete: _deleteLog,
                    );
                  }),

                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}

class _MacroPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MacroPill(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ]),
      );
}

class _MealSection extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Map<String, dynamic>> logs;
  final void Function(int) onDelete;
  const _MealSection(
      {required this.label,
      required this.icon,
      required this.logs,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ]),
        ),
        if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.border.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Belum ada catatan',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          )
        else
          ...logs.map((log) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fastfood,
                        color: AppColors.primary, size: 22),
                  ),
                  title: Text(log['food_name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                      '${double.tryParse(log['calories_consumed'].toString())?.toInt() ?? 0} kkal',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.red, size: 20),
                    onPressed: () => onDelete(log['id'] as int),
                  ),
                ),
              )),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─── Bottom Sheet: Tambah Makanan ────────────────────────────────────────────
class _AddMealSheet extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddMealSheet({required this.onAdded});

  @override
  State<_AddMealSheet> createState() => _AddMealSheetState();
}

class _AddMealSheetState extends State<_AddMealSheet> {
  final _client = ApiClient();
  final _searchCtrl = TextEditingController();
  final _portionCtrl = TextEditingController(text: '100');

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selected;
  String _mealType = 'breakfast';
  bool _loading = false;

  // Nomor urut request pencarian: respons lama yang datang terlambat diabaikan
  int _searchSeq = 0;
  String? _formError;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _portionCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final seq = ++_searchSeq;
    // Teks diubah setelah memilih → pilihan lama tidak berlaku lagi
    if (_selected != null && q != _selected!['name']) {
      setState(() => _selected = null);
    }
    if (q.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    try {
      final res =
          await _client.get(ApiConstants.foodSearch, params: {'q': q.trim()});
      if (!mounted || seq != _searchSeq) return;
      setState(() => _searchResults =
          List<Map<String, dynamic>>.from(res.data['data'] ?? []));
    } catch (_) {
      if (!mounted || seq != _searchSeq) return;
      setState(() => _searchResults = []);
    }
  }

  Future<void> _save() async {
    if (_selected == null) return;
    final portion = double.tryParse(_portionCtrl.text.replaceAll(',', '.'));
    if (portion == null || portion <= 0 || portion > 5000) {
      setState(() => _formError = 'Porsi harus antara 1 dan 5000 gram');
      return;
    }
    setState(() {
      _loading = true;
      _formError = null;
    });
    try {
      await _client.post(ApiConstants.mealLog, data: {
        'food_id': _selected!['id'],
        'meal_type': _mealType,
        'portion_g': portion,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _formError = ApiClient.errorMessage(e, 'Gagal menyimpan. Coba lagi.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tambah Makanan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          // Cari makanan
          TextField(
            controller: _searchCtrl,
            onChanged: _search,
            decoration: const InputDecoration(
              labelText: 'Cari makanan...',
              prefixIcon: Icon(Icons.search),
            ),
          ),

          // Hasil pencarian
          if (_searchResults.isNotEmpty)
            Container(
              height: 160,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (_, i) {
                  final f = _searchResults[i];
                  return ListTile(
                    dense: true,
                    title: Text(f['name'] ?? ''),
                    subtitle: Text(
                        '${double.tryParse(f['calories'].toString())?.toInt() ?? 0} kkal / 100g',
                        style: const TextStyle(fontSize: 12)),
                    trailing: _selected?['id'] == f['id']
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                    onTap: () => setState(() {
                      _selected = f;
                      _searchResults = [];
                      _searchCtrl.text = f['name'];
                    }),
                  );
                },
              ),
            ),

          if (_selected != null) ...[
            const SizedBox(height: 16),
            // Meal type picker
            DropdownButtonFormField<String>(
              value: _mealType,
              decoration: const InputDecoration(labelText: 'Jenis Makan'),
              items: const [
                DropdownMenuItem(value: 'breakfast', child: Text('Sarapan')),
                DropdownMenuItem(value: 'lunch', child: Text('Makan Siang')),
                DropdownMenuItem(value: 'dinner', child: Text('Makan Malam')),
                DropdownMenuItem(value: 'snack', child: Text('Camilan')),
              ],
              onChanged: (v) => setState(() => _mealType = v!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portionCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Porsi (gram)',
                suffixText: 'g',
              ),
            ),
          ],

          if (_formError != null) ...[
            const SizedBox(height: 12),
            Text(_formError!,
                style: const TextStyle(color: AppColors.red, fontSize: 13)),
          ],

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: (_selected != null && !_loading) ? _save : null,
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
