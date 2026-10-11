import 'package:flutter/material.dart';

import '../../../common/presentation/presentation.dart';
import '../../../core/theming/app_colors.dart';
import '../../../core/theming/sizing_ext.dart';
import '../../domain/game_data.dart';
import '../../domain/general_manager.dart';
import '../dialogs/critical_hits_dialog.dart';
import '../dialogs/settings_dialog.dart';
import '../views/progress_view.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Hero(
      tag: 'home_header',
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          height: 128.h,
          padding: EdgeInsets.symmetric(
            horizontal: 104.r,
            vertical: 16.r,
          ),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(bottom: BorderSide(color: c.outline)),
            boxShadow: [
              BoxShadow(
                color: c.shadow,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: AppViewBuilder<GameData>(
            model: GameData.i,
            builder: (gameData, _) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeaderChip(
                  onTap: () => CriticalHitsDialog().open(),
                  icon: Icons.local_fire_department_rounded,
                  iconColor:
                      gameData.criticalHits > 0 ? c.mainOrange : c.textMute,
                  count: gameData.criticalHits,
                ),
                _HeaderChip(
                  onTap: GeneralManager.i.openScoreBoard,
                  icon: Icons.emoji_events_rounded,
                  iconColor: c.mainYellow,
                  count: gameData.gameCount,
                ),
                _HeaderChip(
                  onTap: () => AppNavigator.main.push(const ProgressView()),
                  icon: Icons.insights_rounded,
                  iconColor: c.accent,
                  count: null,
                ),
                _HeaderChip(
                  onTap: () => SettingsDialog().open(),
                  icon: Icons.settings_rounded,
                  iconColor: c.textMedium,
                  count: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.count,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final radius = BorderRadius.circular(48.r);
    return Material(
      color: c.surfaceAlt,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.r, vertical: 8.r),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56.r, color: iconColor),
              if (count != null) ...[
                SizedBox(width: 14.w),
                Text(
                  count.toString(),
                  style: TextStyle(
                    color: c.textStrong,
                    fontSize: 44.t,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
