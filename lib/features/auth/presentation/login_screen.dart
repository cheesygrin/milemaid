import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/services/auth_service.dart';
import 'package:milemaid/core/services/trip_sync_service.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:milemaid/features/settings/providers/settings_provider.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';

/// Login screen: Google Sign-In plus email/password (sign in or create
/// account). Reached from Settings and after onboarding.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _creating = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<dynamic> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      final email = AuthService.instance.currentUser?.email;
      // Restore trips previously backed up to this account.
      var restored = 0;
      try {
        restored = await TripSyncService.instance.syncOnSignIn();
        ref.read(tripsProvider.notifier).refresh();
        ref.invalidate(vehiclesProvider);
      } catch (_) {}
      if (!mounted) return;
      final msg = restored > 0
          ? 'Signed in as $email. Restored $restored drive(s).'
          : (email == null ? 'Signed in' : 'Signed in as $email');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      if (context.canPop()) context.pop();
    } catch (e) {
      if (e is AuthException && e.code == 'canceled') return;
      if (mounted) setState(() => _error = AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter your email above, then tap Forgot password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } catch (e) {
      if (mounted) setState(() => _error = AuthService.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter both email and password.');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    await _run(() => _creating
        ? AuthService.instance.signUpWithEmail(email, password)
        : AuthService.instance.signInWithEmail(email, password));
  }

  @override
  Widget build(BuildContext context) {
    final service = AuthService.instance;
    return Scaffold(
      appBar: AppBar(title: Text(_creating ? 'Create account' : 'Sign in')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text(
                'Back up your miles to the cloud so you never lose a drive again.',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              SignInWithAppleButton(
                onPressed: _busy ? null : () => _run(service.signInWithApple),
                height: 52,
                style: Theme.of(context).brightness == Brightness.dark
                    ? SignInWithAppleButtonStyle.white
                    : SignInWithAppleButtonStyle.black,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              const SizedBox(height: 12),
              if (service.googleConfigured) ...[
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(service.signInWithGoogle),
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: TextStyle(color: AppColors.textTertiary)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy ? null : _resetPassword,
                  child: const Text('Forgot password?'),
                ),
              ),

              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 13),
                ),
                const SizedBox(height: 12),
              ],

              FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_creating ? 'Create account' : 'Sign in'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          _creating = !_creating;
                          _error = null;
                        }),
                child: Text(_creating
                    ? 'Already have an account? Sign in'
                    : 'No account? Create one'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
