import 'package:flutter/material.dart';

import '../../../core/theming/app_colors.dart';
import '../../../core/theming/sizing_ext.dart';

class ButtonWidget extends StatelessWidget {
  const ButtonWidget({
    super.key,
    required this.onTap,
    required this.label,
    this.color,
    this.height,
  });

  final Color? color;

  /// Fixed height; when null the button grows up to a comfortable maximum.
  final double? height;
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fill = color ?? c.accent;
    final radius = BorderRadius.circular(32.r);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: c.isDark ? fill.withValues(alpha: 0.28) : c.shadow,
            blurRadius: c.isDark ? 30 : 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: fill,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: height ?? 150.r,
              minHeight: height ?? 72.r,
              minWidth: 250.r,
              maxWidth: 800.r,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.r),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 56.t,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: c.onColor(fill),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
