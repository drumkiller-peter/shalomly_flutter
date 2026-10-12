import 'package:flutter/material.dart';
import 'package:shalomly_app/src/core/theme/church_colors.dart';

class AppRoundedCard extends StatelessWidget {
  const AppRoundedCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.elevation = 0,
    this.margin,
    this.padding,
  });

  final Widget child;
  final double borderRadius;
  final double elevation;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: context.churchColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.churchColors.primary.withValues(alpha: 0.28),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: context.churchColors.text.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
