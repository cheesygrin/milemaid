import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/constants/app_strings.dart';
import 'package:milemaid/core/constants/design_tokens.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/shared/widgets/trip_card.dart';

/// Swipe right = Business, swipe left = Personal (MileIQ-style).
class SwipeableTripCard extends StatefulWidget {
  const SwipeableTripCard({
    super.key,
    required this.trip,
    required this.onTap,
    required this.onClassified,
    this.enableSwipe = true,
  });

  final Trip trip;
  final VoidCallback onTap;
  final void Function(TripCategory category) onClassified;
  final bool enableSwipe;

  @override
  State<SwipeableTripCard> createState() => _SwipeableTripCardState();
}

class _SwipeableTripCardState extends State<SwipeableTripCard>
    with SingleTickerProviderStateMixin {
  static const double _classifyThreshold = 72;
  static const double _maxDrag = 120;

  double _dragOffset = 0;
  bool _isExiting = false;
  TripCategory? _pendingCategory;

  late final AnimationController _exitController;
  late final Animation<double> _exitSlide;
  late final AnimationController _springController;
  late final Animation<double> _springAnimation;

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(
      vsync: this,
      duration: AppDurations.normal,
    );
    _exitSlide = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _springController = AnimationController(
      vsync: this,
      duration: AppDurations.fast,
    );
    _springAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutBack),
    );

    _exitController.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      final cat = _pendingCategory;
      if (cat != null) widget.onClassified(cat);
    });
  }

  @override
  void dispose() {
    _exitController.dispose();
    _springController.dispose();
    super.dispose();
  }

  Future<void> _commitClassification(TripCategory category, double exitDirection) async {
    if (_isExiting) return;
    setState(() {
      _isExiting = true;
      _pendingCategory = category;
      _dragOffset = exitDirection * _maxDrag;
    });
    // Stronger haptic on successful classification
    HapticFeedback.heavyImpact();
    await _exitController.forward();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableSwipe || _isExiting) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dx).clamp(-_maxDrag, _maxDrag);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enableSwipe || _isExiting) return;

    // Crossed threshold → classify
    if (_dragOffset >= _classifyThreshold) {
      HapticFeedback.mediumImpact();
      _commitClassification(TripCategory.business, 1);
      return;
    }
    if (_dragOffset <= -_classifyThreshold) {
      HapticFeedback.mediumImpact();
      _commitClassification(TripCategory.personal, -1);
      return;
    }

    // Spring back with nice animation
    _springController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() => _dragOffset = 0);
        _springController.reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableSwipe) {
      return TripCard(trip: widget.trip, onTap: widget.onTap);
    }

    final businessReveal = (_dragOffset / _maxDrag).clamp(0.0, 1.0);
    final personalReveal = (-_dragOffset / _maxDrag).clamp(0.0, 1.0);

    // Color bleed tint on the card itself
    final cardTint = _dragOffset > 0
        ? AppColors.accent.withValues(alpha: businessReveal * 0.15)
        : AppColors.personal.withValues(alpha: personalReveal * 0.15);

    final springOffset = _springController.isAnimating
        ? _springAnimation.value * _dragOffset
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s, vertical: AppSpacing.xs),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.m),
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: _SwipeHint(
                    label: AppStrings.personal,
                    icon: Icons.home_outlined,
                    color: AppColors.personal,
                    alignment: Alignment.centerLeft,
                    opacity: personalReveal,
                  ),
                ),
                Expanded(
                  child: _SwipeHint(
                    label: AppStrings.business,
                    icon: Icons.work_outline,
                    color: AppColors.accent,
                    alignment: Alignment.centerRight,
                    opacity: businessReveal,
                  ),
                ),
              ],
            ),
            AnimatedBuilder(
              animation: Listenable.merge([_exitSlide, _springController]),
              builder: (context, child) {
                final exitExtra = _isExiting ? _exitSlide.value * 80 * (_dragOffset.sign) : 0;
                final currentOffset = _dragOffset + exitExtra - springOffset;
                return Transform.translate(
                  offset: Offset(currentOffset, 0),
                  child: child,
                );
              },
              child: GestureDetector(
                onHorizontalDragUpdate: _onPanUpdate,
                onHorizontalDragEnd: _onPanEnd,
                child: Container(
                  decoration: BoxDecoration(
                    color: cardTint,
                    borderRadius: BorderRadius.circular(AppRadius.m),
                  ),
                  child: TripCard(
                    trip: widget.trip,
                    onTap: widget.onTap,
                    showNeedsReview: !widget.trip.isConfirmed,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({
    required this.label,
    required this.icon,
    required this.color,
    required this.alignment,
    required this.opacity,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Alignment alignment;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: color.withValues(alpha: 0.12 + opacity * 0.2),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      child: Opacity(
        opacity: 0.35 + opacity * 0.65,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (alignment == Alignment.centerLeft) ...[
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: AppTypography.labelLarge.copyWith(color: color)),
            ] else ...[
              Text(label, style: AppTypography.labelLarge.copyWith(color: color)),
              const SizedBox(width: AppSpacing.xs),
              Icon(icon, color: color, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}
