import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/constants/app_strings.dart';
import 'package:milemaid/core/services/auth_service.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/location_service.dart';
import 'package:milemaid/core/services/tracking_service.dart';
import 'package:milemaid/core/services/trip_sync_service.dart';
import 'package:milemaid/features/settings/providers/settings_provider.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _busyAuth = false;

  final List<_OnboardPage> _pages = const [
    _OnboardPage(
      title: AppStrings.onboardingTitle1,
      subtitle: AppStrings.onboardingSubtitle1,
      icon: Icons.drive_eta,
    ),
    _OnboardPage(
      title: AppStrings.onboardingTitle2,
      subtitle: AppStrings.onboardingSubtitle2,
      icon: Icons.description,
    ),
    _OnboardPage(
      title: AppStrings.onboardingTitle3,
      subtitle: AppStrings.onboardingSubtitle3,
      icon: Icons.lock,
    ),
    _OnboardPage(
      title: AppStrings.onboardingTitle4,
      subtitle: AppStrings.onboardingSubtitle4,
      icon: Icons.check_circle,
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final access = await _requestPermissionsWithRationale();

    final db = DatabaseService();
    final current = db.getSettings();
    await db.updateSettings(current.copyWith(hasCompletedOnboarding: true));

    if (access != LocationAccess.denied &&
        access != LocationAccess.servicesDisabled) {
      await TrackingService().startTracking();
    }

    if (mounted) {
      if (access == LocationAccess.whenInUse) {
        await LocationService.showAlwaysPermissionGuide(context);
      }
      if (mounted) context.go('/');
    }
  }

  Future<LocationAccess> _requestPermissionsWithRationale() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.permissionTitle),
        content: const Text(AppStrings.permissionMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not Now')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continue')),
        ],
      ),
    );

    if (proceed != true) return LocationAccess.denied;

    final location = LocationService();
    var access = await location.requestFullLocationAccess();

    // Second prompt: upgrade to Always (iOS often skips this — Settings is the fallback).
    if (access == LocationAccess.whenInUse && mounted) {
      await LocationService.showAlwaysPermissionGuide(context);
      access = await location.getCurrentAccess();
    }

    return access;
  }

  Future<void> _googleSignIn() async {
    if (!AuthService.instance.googleConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Google sign-in is not configured yet. Use email instead.')),
        );
      }
      return;
    }
    setState(() => _busyAuth = true);
    try {
      await AuthService.instance.signInWithGoogle();
      try {
        await TripSyncService.instance.syncOnSignIn();
        ref.read(tripsProvider.notifier).refresh();
        ref.invalidate(vehiclesProvider);
      } catch (_) {}
      await _finishOnboarding();
    } catch (e) {
      if (mounted) {
        setState(() => _busyAuth = false);
        if (e is AuthException && e.code == 'canceled') return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.friendlyMessage(e))),
        );
      }
    }
  }

  Future<void> _appleSignIn() async {
    setState(() => _busyAuth = true);
    try {
      await AuthService.instance.signInWithApple();
      try {
        await TripSyncService.instance.syncOnSignIn();
        ref.read(tripsProvider.notifier).refresh();
        ref.invalidate(vehiclesProvider);
      } catch (_) {}
      await _finishOnboarding();
    } catch (e) {
      if (mounted) {
        setState(() => _busyAuth = false);
        if (e is AuthException && e.code == 'canceled') return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.friendlyMessage(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(page.icon, size: 96, color: AppColors.primary),
                        const SizedBox(height: 40),
                        Text(page.title, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(page.subtitle, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SignInWithAppleButton(
                    onPressed: _busyAuth ? null : _appleSignIn,
                    height: 48,
                    style: Theme.of(context).brightness == Brightness.dark
                        ? SignInWithAppleButtonStyle.white
                        : SignInWithAppleButtonStyle.black,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busyAuth ? null : _googleSignIn,
                    icon: const Icon(Icons.g_mobiledata, size: 26),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48)),
                  ),
                  TextButton(
                    onPressed: _busyAuth ? null : () => context.push('/login'),
                    child: const Text('Sign in with email'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => _finishOnboarding(),
                    child: const Text('Skip'),
                  ),
                  const Spacer(),
                  Row(
                    children: List.generate(_pages.length, (i) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i == _currentPage ? AppColors.primary : AppColors.divider,
                      ),
                    )),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(_currentPage == _pages.length - 1 ? "Get Started" : "Next"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  final String title;
  final String subtitle;
  final IconData icon;
  const _OnboardPage({required this.title, required this.subtitle, required this.icon});
}
