// lib/core/api/api_client.dart

import 'package:dio/dio.dart';
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

    // Log request/response di mode debug
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

  Dio get dio => _dio;

  // ─── Helper Methods ──────────────────────────────────────────────────────

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> delete(String path) =>
      _dio.delete(path);

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
