// lib/features/auth/data/auth_repository.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/api/api_client.dart';
import '../../../core/constants/api_constants.dart';
import 'auth_model.dart';

class AuthRepository {
  final _client  = ApiClient();
  final _storage = const FlutterSecureStorage();

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      ApiConstants.register,
      data: {'name': name, 'email': email, 'password': password},
    );
    final user = UserModel.fromJson(res.data['data']);
    await _storage.write(key: 'jwt_token', value: user.token);
    return user;
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    final user = UserModel.fromJson(res.data['data']);
    await _storage.write(key: 'jwt_token', value: user.token);
    return user;
  }

  /// Cek apakah user sudah menyelesaikan onboarding (profil kesehatan).
  /// Jika gagal dicek (mis. server error), anggap sudah agar user tidak terkunci.
  Future<bool> isOnboardingCompleted() async {
    try {
      final res = await _client.get(ApiConstants.onboardingStatus);
      final data = res.data['data'] as Map<String, dynamic>?;
      return data?['onboarding_completed'] as bool? ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }
}
