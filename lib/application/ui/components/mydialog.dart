import 'package:flutter/material.dart';

import '../../../common/presentation/presentation.dart';
import '../../../core/theming/app_colors.dart';
import '../../../core/theming/sizing_ext.dart';

class AppDialog extends StatelessWidget {
  final String heading;
  final Color? color;
  final VoidCallback? onClose;
  final WidgetBuilder builder;

  const AppDialog({
    super.key,
    required this.heading,
    required this.builder,
    this.onClose,
    this.color,
  });

  Future<void> open() {
    return AppNavigator.main.openDialog(dialog: this);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      child: Stack(
        fit: StackFit.loose,
        clipBehavior: Clip.none,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 800),
            padding: EdgeInsets.all(72.r),
            decoration: BoxDecoration(
              color: color ?? c.surface,
              borderRadius: BorderRadius.circular(64.r),
              border: Border.all(color: c.outline),
              boxShadow: [
                BoxShadow(
                  color: c.shadow,
                  blurRadius: 60,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: FittedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    heading,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 52.t,
                      fontWeight: FontWeight.w600,
                      color: c.textStrong,
                    ),
                  ),
                  SizedBox(height: 48.r),
                  builder(context),
                ],
              ),
            ),
          ),
          Positioned(
            top: -28.r,
            right: -28.r,
            child: InkResponse(
              onTap: onClose ?? AppNavigator.of(context).pop,
              child: Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.surfaceAlt,
                  border: Border.all(color: c.outline),
                  boxShadow: [
                    BoxShadow(
                      color: c.shadow,
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 64.r,
                  color: c.textMedium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
