// lib/features/auth/presentation/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/auth_repository.dart';
import '../../../../core/theme/app_theme.dart';

final _authRepo = AuthRepository();

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _loading     = false;
  bool _obscure     = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await _authRepo.login(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      setState(() { _error = 'Email atau password salah'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo / Header
                Center(
                  child: Column(children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color:        AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.restaurant, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text('NutriScan',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text('Deteksi nutrisi makananmu dengan AI',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                  ]),
                ),

                const SizedBox(height: 48),
                const Text('Masuk', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),

                // Email field
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText:   'Email',
                    prefixIcon:  Icon(Icons.email_outlined),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText:  'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Password minimal 6 karakter' : null,
                ),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:        AppColors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline, color: AppColors.red, size: 18),
                      const SizedBox(width: 8),
                      Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
                    ]),
                  ),
                ],

                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Masuk'),
                ),

                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('Belum punya akun? ', style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text('Daftar sekarang',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
