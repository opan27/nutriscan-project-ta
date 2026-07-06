// lib/core/constants/api_constants.dart (UPDATED)
class ApiConstants {
  ApiConstants._();

  static const String baseUrl =
      'http://192.168.8.162:3000/api'; // Android Emulator
  // static const String baseUrl = 'http://192.168.x.x:3000/api'; // HP fisik

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
