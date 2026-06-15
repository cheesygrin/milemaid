import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/constants/app_strings.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/location_service.dart';
import 'package:milemaid/core/services/tracking_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
