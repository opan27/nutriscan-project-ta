// lib/features/analytics/presentation/screens/analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _client = ApiClient();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _client.get(ApiConstants.weeklyInsight);
      setState(() {
        _data = res.data['data'];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      // Untuk Android, kita hanya tampilkan snackbar — PDF di-download via browser
      // Pada implementasi nyata: gunakan flutter_downloader atau dio untuk simpan file
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'PDF sedang disiapkan... Buka di browser: /api/analytics/export-pdf'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analitik Mingguan'),
        actions: [
          TextButton.icon(
            onPressed: _exporting ? null : _exportPdf,
            icon: _exporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : const Icon(Icons.picture_as_pdf_outlined,
                    color: AppColors.primary, size: 20),
            label:
                const Text('PDF', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_data != null) ..._buildContent(),
                  if (_data == null)
                    const Center(child: Text('Belum ada data mingguan')),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildContent() {
    final dailyStats =
        List<Map<String, dynamic>>.from(_data!['daily_stats'] ?? []);
    final insights = List<String>.from(_data!['insights'] ?? []);
    final avgThis = _data!['avg_this_week'] as Map<String, dynamic>?;
    final avgLast = _data!['avg_last_week'] as Map<String, dynamic>?;
    final changes = _data!['changes'] as Map<String, dynamic>?;

    return [
      // ─── Insight Cards ──────────────────────────────────────────────────
      ...insights.map((ins) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.auto_awesome,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(ins, style: const TextStyle(fontSize: 13))),
            ]),
          )),

      const SizedBox(height: 8),

      // ─── Rata-rata comparison ────────────────────────────────────────────
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Perbandingan Mingguan',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: _CompareCol(
                label: 'Kalori Rata-rata',
                thisWeek:
                    '${double.tryParse(avgThis?['calories']?.toString() ?? '0')?.toInt() ?? 0} kkal',
                lastWeek:
                    '${double.tryParse(avgLast?['calories']?.toString() ?? '0')?.toInt() ?? 0} kkal',
                change: changes?['calories_pct']?.toString(),
                color: AppColors.primary,
              )),
              const VerticalDivider(width: 24),
              Expanded(
                  child: _CompareCol(
                label: 'Gula Rata-rata',
                thisWeek:
                    '${double.tryParse(avgThis?['sugar']?.toString() ?? '0')?.toStringAsFixed(1) ?? '0'} g',
                lastWeek:
                    '${double.tryParse(avgLast?['sugar']?.toString() ?? '0')?.toStringAsFixed(1) ?? '0'} g',
                change: changes?['sugar_pct']?.toString(),
                color: AppColors.yellow,
              )),
            ]),
          ]),
        ),
      ),

      const SizedBox(height: 16),

      // ─── Bar Chart Kalori ────────────────────────────────────────────────
      if (dailyStats.isNotEmpty) ...[
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Kalori 7 Hari Terakhir',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    barGroups: dailyStats.asMap().entries.map((e) {
                      final cal = double.tryParse(
                              e.value['total_calories'].toString()) ??
                          0;
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: cal,
                            color: AppColors.primary,
                            width: 22,
                            borderRadius: BorderRadius.circular(6),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: 2500,
                              color: AppColors.primary.withOpacity(0.06),
                            ),
                          )
                        ],
                      );
                    }).toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final idx = v.toInt();
                            if (idx < 0 || idx >= dailyStats.length)
                              return const SizedBox();
                            final d = DateTime.tryParse(
                                dailyStats[idx]['date'].toString());
                            if (d == null) return const SizedBox();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(DateFormat('E', 'id_ID').format(d),
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // ─── Line Chart Gula ───────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Konsumsi Gula 7 Hari',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: LineChart(LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: dailyStats
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                                e.key.toDouble(),
                                double.tryParse(
                                        e.value['total_sugar'].toString()) ??
                                    0,
                              ))
                          .toList(),
                      isCurved: true,
                      color: AppColors.yellow,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.yellow.withOpacity(0.1),
                      ),
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final idx = v.toInt();
                          if (idx < 0 || idx >= dailyStats.length)
                            return const SizedBox();
                          final d = DateTime.tryParse(
                              dailyStats[idx]['date'].toString());
                          if (d == null) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(DateFormat('E', 'id_ID').format(d),
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                )),
              ),
            ]),
          ),
        ),
      ],

      const SizedBox(height: 24),
    ];
  }
}

class _CompareCol extends StatelessWidget {
  final String label, thisWeek, lastWeek;
  final String? change;
  final Color color;
  const _CompareCol(
      {required this.label,
      required this.thisWeek,
      required this.lastWeek,
      required this.color,
      this.change});

  @override
  Widget build(BuildContext context) {
    final changeNum = double.tryParse(change ?? '');
    final isUp = (changeNum ?? 0) > 0;
    final changeColor = isUp ? AppColors.red : AppColors.green;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      Text(thisWeek,
          style: TextStyle(
              fontWeight: FontWeight.w700, color: color, fontSize: 18)),
      const SizedBox(height: 2),
      Text('Minggu lalu: $lastWeek',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      if (changeNum != null) ...[
        const SizedBox(height: 4),
        Row(children: [
          Icon(isUp ? Icons.trending_up : Icons.trending_down,
              color: changeColor, size: 14),
          const SizedBox(width: 4),
          Text('${changeNum.abs()}%',
              style: TextStyle(
                  color: changeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]),
      ],
    ]);
  }
}
