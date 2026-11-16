// lib/core/api/api_client.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../constants/api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl:        ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        contentType:    'application/json',
      ),
    );

    // Interceptor: otomatis sisipkan JWT ke setiap request
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          // Token expired → arahkan ke login
          if (error.response?.statusCode == 401) {
            _storage.delete(key: 'jwt_token');
            // Router akan mendeteksi token null dan redirect ke login
          }
          return handler.next(error);
        },
      ),
    );

    // Log request/response HANYA di mode debug
    // (di release, log ini membocorkan password & token JWT ke logcat)
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader:  true,
          requestBody:    true,
          responseBody:   true,
          responseHeader: false,
          compact:        true,
        ),
      );
    }
  }

  Dio get dio => _dio;

  /// Ambil pesan error yang ramah pengguna dari exception Dio.
  /// Prioritas: pesan `message` dari backend → pesan koneksi → [fallback].
  static String errorMessage(Object error, [String fallback = 'Terjadi kesalahan. Coba lagi.']) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String && (data['message'] as String).isNotEmpty) {
        return data['message'] as String;
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          return 'Tidak dapat terhubung ke server. Pastikan HP & laptop di Wi-Fi yang sama.';
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Server terlalu lama merespons. Coba lagi.';
        case DioExceptionType.connectionError:
          return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
        default:
          break;
      }
    }
    return fallback;
  }

  // ─── Helper Methods ──────────────────────────────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) =>
      _dio.delete(path);

  /// Unduh file (mis. PDF laporan) ke [savePath]. Token JWT ikut terkirim
  /// lewat interceptor, jadi endpoint yang butuh login tetap bisa diakses.
  Future<Response> download(String path, String savePath,
          {Map<String, dynamic>? params}) =>
      _dio.download(
        path,
        savePath,
        queryParameters: params,
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );

  /// Upload gambar multipart (untuk scan)
  Future<Response> uploadImage(String path, String filePath, {Map<String, dynamic>? extra}) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
      if (extra != null) ...extra,
    });
    return _dio.post(
      path,
      data:    formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
