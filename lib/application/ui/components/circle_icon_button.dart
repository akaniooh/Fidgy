import 'package:flutter/material.dart';

import '../../../core/theming/app_colors.dart';
import '../../../core/theming/sizing_ext.dart';

/// Round floating icon button (home / back).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.surface,
      elevation: 6,
      shadowColor: c.shadow,
      surfaceTintColor: Colors.transparent,
      shape: CircleBorder(side: BorderSide(color: c.outline)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 112.r,
          height: 112.r,
          child: Icon(icon, size: 56.r, color: c.accent),
        ),
      ),
    );
  }
}
