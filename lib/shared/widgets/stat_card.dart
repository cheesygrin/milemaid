import 'package:flutter/material.dart';

/// Reusable metric card used on Dashboard. Optionally tappable.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  /// Mileage tiles use a large tabular figure. Counts use a quieter treatment.
  final bool emphasizeValue;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.onTap,
    this.emphasizeValue = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = accentColor ?? scheme.primary;
    final muted = scheme.onSurfaceVariant;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: emphasizeValue ? 20 : 22),
                const SizedBox(height: 8),
              ],
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: muted),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: emphasizeValue ? 26 : 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: emphasizeValue ? -0.5 : 0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: scheme.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: TextStyle(fontSize: 12, color: muted)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}