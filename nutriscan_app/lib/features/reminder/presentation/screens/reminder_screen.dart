// lib/features/reminder/presentation/screens/reminder_screen.dart

import 'package:flutter/material.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final _client = ApiClient();
  List<Map<String, dynamic>> _reminders = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client.get(ApiConstants.reminder);
      setState(() { _reminders = List<Map<String, dynamic>>.from(res.data['data']); _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(int id) async {
    await _client.put('${ApiConstants.reminder}/$id/toggle');
    _load();
  }

  Future<void> _delete(int id) async {
    await _client.delete('${ApiConstants.reminder}/$id');
    _load();
  }

  Future<void> _showAddSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddReminderSheet(),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final medicine = _reminders.where((r) => r['type'] == 'medicine').toList();
    final water    = _reminders.where((r) => r['type'] == 'water').toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Pengingat')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSheet,
        backgroundColor: AppColors.primary,
        icon:  const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection('💊 Pengingat Obat', medicine, Icons.medication_outlined, Colors.blue),
              const SizedBox(height: 16),
              _buildSection('💧 Pengingat Minum Air', water, Icons.water_drop_outlined, Colors.lightBlue),
              const SizedBox(height: 80),
            ],
          ),
    );
  }

  Widget _buildSection(String title, List reminders, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 10),
        if (reminders.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.border.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Icon(icon, color: color.withOpacity(0.4)),
              const SizedBox(width: 12),
              Text('Belum ada pengingat', style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7))),
            ]),
          )
        else
          ...reminders.map((r) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color:        color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              title: Text(r['label'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('${r['time']}  •  ${r['days'] ?? 'Setiap hari'}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Switch(
                  value:          r['is_active'] == 1,
                  activeThumbColor:    AppColors.primary,
                  onChanged:      (_) => _toggle(r['id'] as int),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                  onPressed: () => _delete(r['id'] as int),
                ),
              ]),
            ),
          )),
      ],
    );
  }
}

// ─── Add Reminder Sheet ───────────────────────────────────────────────────────
class _AddReminderSheet extends StatefulWidget {
  const _AddReminderSheet();

  @override
  State<_AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends State<_AddReminderSheet> {
  final _client    = ApiClient();
  final _labelCtrl = TextEditingController();
  String   _type    = 'medicine';
  TimeOfDay _time   = TimeOfDay.now();
  bool     _loading = false;

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_labelCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final timeStr = '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}:00';
    try {
      await _client.post(ApiConstants.reminder, data: {
        'type':  _type,
        'label': _labelCtrl.text.trim(),
        'time':  timeStr,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tambah Pengingat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          // Tipe pengingat
          Row(children: [
            _TypeBtn(label: '💊 Obat',     value: 'medicine', selected: _type, onTap: (v) => setState(() => _type = v)),
            const SizedBox(width: 10),
            _TypeBtn(label: '💧 Air Minum', value: 'water',    selected: _type, onTap: (v) => setState(() => _type = v)),
          ]),
          const SizedBox(height: 14),

          TextField(
            controller: _labelCtrl,
            decoration: InputDecoration(
              labelText: _type == 'medicine' ? 'Nama Obat (misal: Metformin 500mg)' : 'Label (misal: Minum 2 gelas)',
            ),
          ),
          const SizedBox(height: 14),

          // Time picker
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border:       Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.access_time, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: 12),
                Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const Spacer(),
                const Text('Ubah waktu', style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ]),
            ),
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : const Text('Simpan Pengingat'),
          ),
        ],
      ),
    );
  }
}

class _TypeBtn extends StatelessWidget {
  final String label, value, selected;
  final void Function(String) onTap;
  const _TypeBtn({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:        active ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: active ? AppColors.primary : AppColors.border),
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:      active ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            )),
        ),
      ),
    );
  }
}
