// lib/features/scan/presentation/screens/scan_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/scan_repository.dart';
import '../../data/scan_model.dart';
import '../../../../core/theme/app_theme.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _repo = ScanRepository();
  final _picker = ImagePicker();

  File? _image;
  ScanResponse? _result;
  bool _loading = false;
  String? _error;

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;
    setState(() {
      _image = File(picked.path);
      _result = null;
      _error = null;
    });
    await _runScan(picked.path);
  }

  Future<void> _runScan(String path) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _repo.scanFood(path);
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memindai. Coba lagi dengan foto yang lebih jelas.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai Makanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Image preview area
            GestureDetector(
              onTap: () => _showPickerSheet(),
              child: Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3), width: 1.5),
                ),
                child: _image == null
                    ? _buildEmptyPickerHint()
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(19),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Pick buttons
            Row(children: [
              Expanded(
                child: _OutlineBtn(
                  icon: Icons.camera_alt_outlined,
                  label: 'Kamera',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OutlineBtn(
                  icon: Icons.photo_library_outlined,
                  label: 'Galeri',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ]),

            const SizedBox(height: 24),

            // Loading state
            if (_loading) const _LoadingCard(),

            // Error state
            if (_error != null) _ErrorCard(message: _error!),

            // Result
            if (_result != null && !_loading)
              _MultiScanResultCard(result: _result!),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPickerHint() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.document_scanner_outlined,
              size: 56, color: AppColors.primary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text('Tap untuk ambil foto',
              style: TextStyle(
                  color: AppColors.primary.withOpacity(0.7),
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('atau pilih dari galeri',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ],
      );

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  RESULT CARD
// ─────────────────────────────────────────────

class _MultiScanResultCard extends StatelessWidget {
  final ScanResponse result;

  const _MultiScanResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Summary banner ──────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppColors.primary.withOpacity(0.2), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.restaurant_menu,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${result.totalObjects} makanan terdeteksi',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total ${result.totalNutrition.calories.toStringAsFixed(0)} kkal',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Disclaimer takaran ──────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nilai gizi dihitung per 100 g BDD (Berat yang Dapat Dimakan = 100%). '
                  'Angka ini merupakan estimasi berdasarkan komposisi standar bahan makanan.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade900,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Per-food cards ──────────────────────────
        ...result.foods.map((food) => _FoodNutritionCard(food: food)),

        const SizedBox(height: 8),

        // ── Total nutrition ─────────────────────────
        _TotalNutritionCard(nutrition: result.totalNutrition),

        const SizedBox(height: 12),

        // ── Source note ─────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 15, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey.shade700,
                        height: 1.5),
                    children: const [
                      TextSpan(
                        text: 'Sumber data: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: 'Tabel Komposisi Pangan Indonesia (TKPI) 2017 — '
                            'Kementerian Kesehatan RI. '
                            'Data tersedia di ',
                      ),
                      TextSpan(
                        text: 'panganku.org',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      TextSpan(text: '.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  INDIVIDUAL FOOD CARD
// ─────────────────────────────────────────────

class _FoodNutritionCard extends StatelessWidget {
  final dynamic food; // FoodItem from ScanModel

  const _FoodNutritionCard({required this.food});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food name row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fastfood_outlined,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  food.foodName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: Text(
              'per 100 g BDD',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Nutrisi grid
          _NutrientRow(
            icon: Icons.local_fire_department_outlined,
            iconColor: Colors.deepOrange,
            label: 'Energi',
            value: '${food.nutrition.calories.toStringAsFixed(1)} kkal',
          ),
          const SizedBox(height: 8),
          _NutrientRow(
            icon: Icons.grain_outlined,
            iconColor: Colors.amber.shade700,
            label: 'Karbohidrat',
            value: '${food.nutrition.carbohydrates.toStringAsFixed(1)} g',
          ),
          const SizedBox(height: 8),
          _NutrientRow(
            icon: Icons.fitness_center_outlined,
            iconColor: Colors.blue.shade600,
            label: 'Protein',
            value: '${food.nutrition.protein.toStringAsFixed(1)} g',
          ),
          const SizedBox(height: 8),
          _NutrientRow(
            icon: Icons.opacity_outlined,
            iconColor: Colors.green.shade600,
            label: 'Lemak',
            value: '${food.nutrition.fat.toStringAsFixed(1)} g',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  TOTAL NUTRITION CARD
// ─────────────────────────────────────────────

class _TotalNutritionCard extends StatelessWidget {
  final dynamic nutrition; // NutritionInfo from ScanModel

  const _TotalNutritionCard({required this.nutrition});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.summarize_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Total Nutrisi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TotalNutrientChip(
                  label: 'Energi',
                  value: '${nutrition.calories.toStringAsFixed(0)}',
                  unit: 'kkal',
                  color: Colors.deepOrange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TotalNutrientChip(
                  label: 'Karbo',
                  value: '${nutrition.carbohydrates.toStringAsFixed(1)}',
                  unit: 'g',
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TotalNutrientChip(
                  label: 'Protein',
                  value: '${nutrition.protein.toStringAsFixed(1)}',
                  unit: 'g',
                  color: Colors.blue.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TotalNutrientChip(
                  label: 'Lemak',
                  value: '${nutrition.fat.toStringAsFixed(1)}',
                  unit: 'g',
                  color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalNutrientChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _TotalNutrientChip({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            unit,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  NUTRIENT ROW
// ─────────────────────────────────────────────

class _NutrientRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _NutrientRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  REUSABLE WIDGETS
// ─────────────────────────────────────────────

class _OutlineBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _OutlineBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(0, 48),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: const [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('AI sedang menganalisis makanan...',
                style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Text('Mohon tunggu sebentar',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ]),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.red.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.error_outline, color: AppColors.red),
            const SizedBox(width: 12),
            Expanded(
                child: Text(message,
                    style: const TextStyle(color: AppColors.red))),
          ]),
        ),
      );
}
