// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api/api_client.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/scan/presentation/screens/scan_screen.dart';
import '../../features/meal_log/presentation/screens/meal_log_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/reminder/presentation/screens/reminder_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash — cek token & onboarding
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),

      // Auth
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Onboarding (setelah login pertama kali)
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // Main shell dengan bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/scan', builder: (_, __) => const ScanScreen()),
          GoRoute(path: '/meal-log', builder: (_, __) => const MealLogScreen()),
          GoRoute(
              path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Sub-pages (tanpa bottom nav)
      GoRoute(path: '/reminder', builder: (_, __) => const ReminderScreen()),
      GoRoute(
          path: '/profile/edit', builder: (_, __) => const EditProfileScreen()),
    ],
  );
});

// ─── Splash Screen ────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    if (token == null) {
      if (mounted) context.go('/login');
      return;
    }

    // Cek apakah onboarding sudah selesai
    try {
      final client = ApiClient();
      final res = await client.get('/health/onboarding-status');
      final data = res.data['data'] as Map<String, dynamic>;
      final done = data['onboarding_completed'] as bool? ?? false;
      if (mounted) {
        context.go(done ? '/home' : '/onboarding');
      }
    } catch (_) {
      // Kalau gagal hit API (misal offline), langsung ke home
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E7D32),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.restaurant, color: Colors.white, size: 48),
          ),
          const SizedBox(height: 20),
          const Text('NutriScan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              )),
          const SizedBox(height: 8),
          Text('Makan sehat, hidup berkualitas',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              )),
          const SizedBox(height: 48),
          const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ]),
      ),
    );
  }
}

// ─── Main Shell dengan Bottom Nav ────────────────────────────────────────────
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(
        path: '/home',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Beranda'),
    _TabItem(
        path: '/scan',
        icon: Icons.document_scanner_outlined,
        activeIcon: Icons.document_scanner,
        label: 'Pindai'),
    _TabItem(
        path: '/meal-log',
        icon: Icons.book_outlined,
        activeIcon: Icons.book,
        label: 'Log Makan'),
    // _TabItem(path: '/analytics', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Analitik'),
    _TabItem(
        path: '/profile',
        icon: Icons.person_outlined,
        activeIcon: Icons.person,
        label: 'Profil'),
  ];

  int _currentIndex(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _currentIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2E7D32).withOpacity(0.12),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon:
                      Icon(t.activeIcon, color: const Color(0xFF2E7D32)),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem(
      {required this.path,
      required this.icon,
      required this.activeIcon,
      required this.label});
}
