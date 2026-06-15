import 'package:flutter/material.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/models/trip.dart';

/// Beautiful small category pill used on TripCard and filters.
class CategoryChip extends StatelessWidget {
  final TripCategory category;
  final bool compact;

  const CategoryChip({super.key, required this.category, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.forCategory(category);
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
          Text(category.icon, style: TextStyle(fontSize: compact ? 10 : 12)),
          const SizedBox(width: 4),
          Text(
            category.displayName,
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
