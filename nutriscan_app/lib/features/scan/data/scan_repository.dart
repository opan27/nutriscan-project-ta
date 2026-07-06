// lib/features/scan/data/scan_repository.dart

import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'scan_model.dart';

class ScanRepository {
  final _client = ApiClient();

  /// Upload foto ke backend, terima hasil deteksi + nutrisi
  Future<ScanResponse> scanFood(String imagePath,
      {double portionG = 100}) async {
    final res = await _client.uploadImage(
      ApiConstants.scan,
      imagePath,
      extra: {'portion_g': portionG.toString()},
    );

    if (res.data['success'] != true) {
      throw Exception(res.data['message'] ?? 'Gagal memindai makanan');
    }

    return ScanResponse.fromJson(res.data['data']);
  }

  /// Kirim feedback koreksi ke backend (untuk akurasi model skripsi)
  Future<void> sendFeedback(
    int scanId, {
    required String actualLabel,
    required bool isCorrect,
  }) async {
    await _client.post(
      '${ApiConstants.scan}/$scanId/feedback',
      data: {'actual_label': actualLabel, 'is_correct': isCorrect},
    );
  }

  /// Ambil riwayat scan
  Future<List<Map<String, dynamic>>> getScanHistory({int limit = 20}) async {
    final res =
        await _client.get(ApiConstants.scanHistory, params: {'limit': limit});
    return List<Map<String, dynamic>>.from(res.data['data']);
  }
}
