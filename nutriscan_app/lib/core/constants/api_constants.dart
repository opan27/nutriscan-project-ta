// lib/core/constants/api_constants.dart (UPDATED)
class ApiConstants {
  ApiConstants._();

  // IP laptop BERUBAH setiap ganti jaringan Wi-Fi/hotspot.
  // Cek IP laptop: jalankan `ipconfig` → "IPv4 Address" di adapter Wi-Fi.
  // Bisa di-override tanpa edit file:
  //   flutter run --dart-define=API_BASE_URL=http://192.168.x.x:3000/api
  // Emulator Android: http://10.0.2.2:3000/api
  // Setelah ganti URL, WAJIB hot restart (R), bukan hot reload (r).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.8.177:3000/api',
  );

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String me = '/auth/me';

  // Scan
  static const String scan = '/scan';
  static const String scanHistory = '/scan/history';

  // Food
  static const String foodSearch = '/food/search';

  // Meal Log
  static const String mealLog = '/meal-log';
  static const String mealLogToday = '/meal-log/today';

  // Health & Profil
  static const String healthProfile = '/health/profile';
  static const String healthRecommendation = '/health/recommendation'; // ← BARU
  static const String onboardingStatus = '/health/onboarding-status'; // ← BARU

  // Analytics
  static const String weeklyInsight = '/analytics/weekly';
  static const String exportPdf = '/analytics/export-pdf';

  // Reminder
  static const String reminder = '/reminder';

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
}
