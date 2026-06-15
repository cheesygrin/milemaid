import 'package:flutter/material.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/constants/design_tokens.dart';

/// Classification success animation.
/// 
/// To use a real Rive animation:
/// 1. Create or download a .riv file from https://rive.app
/// 2. Place it in assets/rive/ (e.g. assets/rive/classify_success.riv)
/// 3. Replace the placeholder below with RiveAnimation.asset(...)
class ClassificationSuccess extends StatelessWidget {
  const ClassificationSuccess({
    super.key,
    required this.category,
    this.size = 120,
  });

  final String category; // 'Business' or 'Personal'
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = category.toLowerCase().contains('business')
        ? AppColors.accent
        : AppColors.personal;

    // TODO: Replace with real Rive file when available
    // Example:
    // return SizedBox(
    //   width: size,
    //   height: size,
    //   child: RiveAnimation.asset(
    //     'assets/rive/classify_success.riv',
    //     artboard: category.toLowerCase().contains('business') ? 'Business' : 'Personal',
    //     fit: BoxFit.contain,
    //   ),
    // );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.75,
            height: size * 0.75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.12),
            ),
          ),
          Icon(
            Icons.check_circle_rounded,
            size: size * 0.55,
            color: color,
          ),
        ],
      ),
    );
  }
}

/// Beautiful empty state for "No trips to classify".
/// 
/// Replace the container with a Rive illustration when ready:
/// assets/rive/empty_classify.riv
class ClassifyEmptyState extends StatelessWidget {
  const ClassifyEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Placeholder for Rive illustration
            // Replace with:
            // RiveAnimation.asset('assets/rive/empty_classify.riv', fit: BoxFit.contain)
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: const Icon(
                Icons.drive_eta_outlined,
                size: 80,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.l),
            Text(
              'All caught up',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              'Every drive has been classified.\nNew trips will appear here automatically.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
