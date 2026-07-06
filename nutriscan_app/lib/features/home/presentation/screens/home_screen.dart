// lib/features/home/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _client = ApiClient();
  final _storage = const FlutterSecureStorage();

  Map<String, dynamic>? _todayLog;
  Map<String, dynamic>? _profile;
  String _userName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Parse aman: terima String "19.61", int 19, double 19.61 → selalu double
  double _toDouble(dynamic v, [double fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }

  Future<void> _loadData() async {
    try {
      final responses = await Future.wait([
        _client.get(ApiConstants.me),
        _client.get(ApiConstants.mealLogToday),
        _client.get(ApiConstants.healthProfile).catchError((_) => null),
      ]);

      if (mounted) {
        setState(() {
          _userName = responses[0].data['data']['name']?.toString() ?? '';
          _todayLog = responses[1].data['data'] as Map<String, dynamic>?;
          _profile = responses[2].data['data'] as Map<String, dynamic>?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: 'jwt_token');
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greeting(now.hour);
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    final calConsumed = _toDouble(_todayLog?['total_today']?['calories']);
    final calTarget = _toDouble(_todayLog?['calorie_target'], 2000);
    final calPct = (calConsumed / calTarget).clamp(0.0, 1.0);
    final calRemain = _toDouble(_todayLog?['calorie_remaining'], calTarget);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ─── App Bar ───────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                  onPressed: () => context.push('/reminder'),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: _logout,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(greeting,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              )),
                          const SizedBox(height: 4),
                          Text(_loading ? '...' : _userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              )),
                          const SizedBox(height: 4),
                          Text(dateStr,
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 13,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ─── Kalori Card ─────────────────────────────────────────
                  _buildCalorieCard(calConsumed, calTarget, calPct, calRemain),
                  const SizedBox(height: 16),

                  // ─── Quick Actions ───────────────────────────────────────
                  const Text('Menu Cepat',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _buildQuickActions(context),
                  const SizedBox(height: 20),

                  // ─── Nutrisi Hari Ini ────────────────────────────────────
                  const Text('Nutrisi Hari Ini',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _buildNutritionSummary(),
                  const SizedBox(height: 20),

                  // ─── Profil Kesehatan Banner ─────────────────────────────
                  if (_profile == null && !_loading)
                    _buildProfileBanner(context),
                  if (_profile != null) _buildBmiCard(),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieCard(
      double consumed, double target, double pct, double remain) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Kalori Hari Ini',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            Text('${consumed.toInt()} / ${target.toInt()} kkal',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ]),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 12,
              backgroundColor: AppColors.primary.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(
                pct > 0.9
                    ? AppColors.red
                    : pct > 0.75
                        ? AppColors.yellow
                        : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _CalPill(
                label: 'Tersisa',
                value: '${remain.toInt()} kkal',
                color: remain < 0 ? AppColors.red : AppColors.primary),
            _CalPill(
                label: 'Progres',
                value: '${(pct * 100).toInt()}%',
                color: AppColors.textSecondary),
          ]),
        ]),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      _QuickAction(
          icon: Icons.document_scanner,
          label: 'Pindai\nMakanan',
          color: AppColors.primary,
          path: '/scan'),
      _QuickAction(
          icon: Icons.add_circle_outline,
          label: 'Catat\nMakan',
          color: Colors.orange,
          path: '/meal-log'),
      _QuickAction(
          icon: Icons.bar_chart,
          label: 'Laporan\nMingguan',
          color: Colors.blue,
          path: '/analytics'),
      _QuickAction(
          icon: Icons.person,
          label: 'Profil\nKesehatan',
          color: Colors.purple,
          path: '/profile'),
    ];

    return Row(
      children: actions
          .map((a) => Expanded(
                child: GestureDetector(
                  onTap: () => context.go(a.path),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: a.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: a.color.withOpacity(0.2)),
                    ),
                    child: Column(children: [
                      Icon(a.icon, color: a.color, size: 28),
                      const SizedBox(height: 8),
                      Text(a.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              color: a.color,
                              fontWeight: FontWeight.w500,
                              height: 1.3)),
                    ]),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildNutritionSummary() {
    final total = _todayLog?['total_today'] as Map<String, dynamic>?;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          _NutriItem(
              label: 'Karbo',
              value: '${_toDouble(total?['carbs']).toInt()}g',
              color: Colors.blue),
          _NutriItem(
              label: 'Protein',
              value: '${_toDouble(total?['protein']).toInt()}g',
              color: Colors.orange),
          _NutriItem(
              label: 'Lemak',
              value: '${_toDouble(total?['fat']).toInt()}g',
              color: Colors.purple),
          _NutriItem(
              label: 'Gula',
              value: '${_toDouble(total?['sugar']).toInt()}g',
              color: AppColors.yellow),
        ]),
      ),
    );
  }

  Widget _buildProfileBanner(BuildContext context) => GestureDetector(
        onTap: () => context.go('/profile'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.yellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.yellow.withOpacity(0.4)),
          ),
          child: Row(children: const [
            Icon(Icons.info_outline, color: AppColors.yellow),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                  'Lengkapi profil kesehatanmu agar sistem pakar dapat bekerja optimal',
                  style: TextStyle(fontSize: 13)),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ]),
        ),
      );

  Widget _buildBmiCard() {
    final bmi = _toDouble(_profile?['bmi']);
    final cat = _profile?['bmi_category']?.toString() ?? '-';
    final color = _hexColor(_profile?['bmi_color']?.toString() ?? '#4CAF50');
    final target = _toDouble(_profile?['daily_calorie_target']);
    final cond = _profile?['medical_condition']?.toString() ?? 'none';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
              child: _StatItem(
                  label: 'BMI',
                  value: bmi.toStringAsFixed(1),
                  sub: cat,
                  color: color)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
              child: _StatItem(
                  label: 'Target Kalori',
                  value: '${target.toInt()}',
                  sub: 'kkal/hari',
                  color: AppColors.primary)),
          Container(width: 1, height: 40, color: AppColors.border),
          Expanded(
              child: _StatItem(
                  label: 'Kondisi',
                  value: cond == 'none' ? 'Sehat' : cond,
                  sub: 'medis',
                  color: Colors.teal)),
        ]),
      ),
    );
  }

  String _greeting(int hour) {
    if (hour < 11) return 'Selamat Pagi 🌅';
    if (hour < 15) return 'Selamat Siang ☀️';
    if (hour < 18) return 'Selamat Sore 🌤️';
    return 'Selamat Malam 🌙';
  }

  Color _hexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.green;
    }
  }
}

class _CalPill extends StatelessWidget {
  final String label, value;
  final Color color;
  const _CalPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        ],
      );
}

class _QuickAction {
  final IconData icon;
  final String label, path;
  final Color color;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.path});
}

class _NutriItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _NutriItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
          child: Column(children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w700, color: color, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]));
}

class _StatItem extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  const _StatItem(
      {required this.label,
      required this.value,
      required this.sub,
      required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 16)),
          Text(sub,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ]),
      );
}
