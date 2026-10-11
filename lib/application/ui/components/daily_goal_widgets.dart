import 'dart:math';

import 'package:flutter/material.dart';

import '../../../common/presentation/presentation.dart';
import '../../domain/app_settings.dart';
import '../../domain/game_data.dart';
import '../../domain/suggestions.dart';
import '../dialogs/settings_dialog.dart';

/// "Today: 1 of 2" progress ring plus the consecutive-days count.
class DailyGoalRow extends StatelessWidget {
  const DailyGoalRow({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppViewBuilder<GameData>(
      model: GameData.i,
      builder: (data, _) => AppViewBuilder<AppSettings>(
        model: AppSettings.i,
        builder: (settings, __) {
          final goal = settings.dailyGoal;
          final done = data.dailyCount;
          final met = done >= goal;
          final streak = data.dayStreak;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Pill(
                leading: SizedBox(
                  width: 44.r,
                  height: 44.r,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: min(1.0, done / goal),
                        strokeWidth: 5,
                        backgroundColor: c.neutralFill,
                        color: met ? c.mainGreen : c.accent,
                      ),
                      if (met)
                        Icon(Icons.check_rounded, size: 26.r, color: c.mainGreen),
                    ],
                  ),
                ),
                label: met ? 'Goal reached today' : 'Today: $done of $goal',
              ),
              if (streak > 0) ...[
                SizedBox(width: 20.r),
                _Pill(
                  leading: Icon(
                    Icons.event_available_rounded,
                    size: 44.r,
                    color: c.accent,
                  ),
                  label: streak == 1 ? '1 day' : '$streak days in a row',
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.leading, required this.label});

  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 28.r, vertical: 12.r),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(48.r),
        border: Border.all(color: c.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          SizedBox(width: 16.r),
          Text(
            label,
            style: TextStyle(
              fontSize: 32.t,
              fontWeight: FontWeight.w500,
              color: c.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

/// A dismissible nudge under the header, only shown when there is one.
class SuggestionBanner extends StatelessWidget {
  const SuggestionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return AppViewBuilder<Suggestions>(
      model: Suggestions.i,
      builder: (suggestions, _) {
        final current = suggestions.current;
        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.topCenter,
          child: current == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: EdgeInsets.fromLTRB(80.r, 20.r, 80.r, 0),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 28.r,
                      vertical: 12.r,
                    ),
                    decoration: BoxDecoration(
                      color: c.surfaceAlt,
                      borderRadius: BorderRadius.circular(32.r),
                      border: Border.all(
                        color: c.accent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 44.r,
                          color: c.accent,
                        ),
                        SizedBox(width: 20.r),
                        Expanded(
                          child: Text(
                            current.message,
                            style: TextStyle(
                              fontSize: 28.t,
                              color: c.textStrong,
                            ),
                          ),
                        ),
                        if (current.opensSettings)
                          TextButton(
                            onPressed: () => SettingsDialog().open(),
                            child: Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 28.t,
                                fontWeight: FontWeight.w600,
                                color: c.accent,
                              ),
                            ),
                          ),
                        IconButton(
                          tooltip: 'Dismiss',
                          onPressed: suggestions.dismiss,
                          icon: Icon(
                            Icons.close_rounded,
                            size: 40.r,
                            color: c.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
