import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../profile_screen.dart';
import '../admin/admin_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
  setState(() { _loading = true; _error = null; });
  try {
    await ref.read(authServiceProvider).signInWithEmail(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    if (mounted) context.go('/home');
  } catch (e) {
    setState(() => _error = e.toString().replaceAll('Exception: ', ''));
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Row(children: [
                const Icon(Icons.favorite, color: VitalSenseTheme.primaryBlue, size: 32),
                const SizedBox(width: 10),
                Text('VitalSense', style: Theme.of(context).textTheme.displayLarge?.copyWith(color: VitalSenseTheme.primaryBlue)),
              ]).animate().fadeIn(duration: 500.ms).slideX(begin: -0.2),
              const SizedBox(height: 8),
              Text('Welcome back', style: Theme.of(context).textTheme.displayMedium).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
              Text('Sign in to monitor your health', style: Theme.of(context).textTheme.bodyMedium).animate(delay: 150.ms).fadeIn(),
              const SizedBox(height: 40),

              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: VitalSenseTheme.alertRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: VitalSenseTheme.alertRed.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, color: VitalSenseTheme.alertRed, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: const TextStyle(color: VitalSenseTheme.alertRed, fontSize: 13))),
                  ]),
                ).animate().fadeIn().shakeX(),

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
              const SizedBox(height: 14),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onSubmitted: (_) => _login(),
              ).animate(delay: 250.ms).fadeIn().slideY(begin: 0.2),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Sign In'),
                ),
              ).animate(delay: 300.ms).fadeIn(),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/signup'),
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: const [
                        TextSpan(text: 'Sign Up', style: TextStyle(color: VitalSenseTheme.primaryBlue, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              const Center(child: Text('STAFF & ADMIN ACCESS', style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.2))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.medical_services, size: 16, color: Color(0xFF00e5ff)),
                      label: const Text('Doctor', style: TextStyle(color: Color(0xFF00e5ff), fontSize: 12)),
                      onPressed: () => context.push('/home/doctor'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.admin_panel_settings, size: 16, color: Color(0xFFffab00)),
                      label: const Text('Admin', style: TextStyle(color: Color(0xFFffab00), fontSize: 12)),
                      onPressed: () => context.push('/home/admin'),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
