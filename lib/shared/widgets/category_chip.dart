import 'package:flutter/material.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/models/trip.dart';

/// Beautiful small category pill used on TripCard and filters.
/// Supports a user-defined custom label + color.
class CategoryChip extends StatelessWidget {
  final TripCategory category;
  final String? customLabel;
  final int? customColorValue;
  final bool compact;

  const CategoryChip({
    super.key,
    required this.category,
    this.customLabel,
    this.customColorValue,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final custom = (customLabel?.isNotEmpty ?? false);
    final color = custom
        ? Color(customColorValue ?? 0xFF607D8B)
        : AppColors.forCategory(category);
    final icon = custom ? '🏷️' : category.icon;
    final text = custom ? customLabel! : category.displayName;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: TextStyle(fontSize: compact ? 10 : 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}