import 'package:flutter/material.dart';

import '../../../common/presentation/presentation.dart';
import '../../data/session_repository.dart';
import '../../domain/app_lock.dart';
import '../../domain/app_settings.dart';
import '../../domain/feedback_service.dart';
import '../components/button_widget.dart';
import '../components/mydialog.dart';
import 'app_lock_dialogs.dart';
import 'info_dialogs.dart';

class SettingsDialog extends AppDialog {
  SettingsDialog({super.key})
      : super(
          heading: 'Settings',
          builder: (ctx) {
            final c = AppColors.of(ctx);
            final h = 96.r;
            final gap = SizedBox(height: 18.h);
            return AppViewBuilder<AppSettings>(
              model: AppSettings.i,
              builder: (settings, _) => Column(
                children: [
                  ButtonWidget(
                    height: h,
                    onTap: () async {
                      await settings.toggleSound();
                      FeedbackService.i.correct();
                    },
                    label: 'Sound: ${settings.soundEnabled ? 'ON' : 'OFF'}',
                    color: settings.soundEnabled ? c.accent : c.neutralFill,
                  ),
                  gap,
                  ButtonWidget(
                    height: h,
                    onTap: () async {
                      await settings.toggleHaptics();
                      FeedbackService.i.correct();
                    },
                    label:
                        'Vibration: ${settings.hapticsEnabled ? 'ON' : 'OFF'}',
                    color: settings.hapticsEnabled ? c.accent : c.neutralFill,
                  ),
                  gap,
                  ButtonWidget(
                    height: h,
                    onTap: () async {
                      await settings.cycleTheme();
                      FeedbackService.i.correct();
                    },
                    label: 'Appearance: ${settings.themeLabel}',
                    color: c.neutralFill,
                  ),
                  gap,
                  ButtonWidget(
                    height: h,
                    onTap: () async {
                      await settings.cycleAssist();
                      FeedbackService.i.correct();
                    },
                    label: 'Assist: ${settings.assistLevel.label}',
                    color: c.neutralFill,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    settings.assistLevel.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30.t, color: c.textMedium),
                  ),
                  SizedBox(height: 16.h),
                  ButtonWidget(
                    height: h,
                    onTap: () async {
                      await settings.cycleDailyGoal();
                      FeedbackService.i.correct();
                    },
                    label: 'Daily goal: ${settings.dailyGoal} '
                        '${settings.dailyGoal == 1 ? 'session' : 'sessions'}',
                    color: c.neutralFill,
                  ),
                  gap,
                  AppViewBuilder<AppLock>(
                    model: AppLock.i,
                    builder: (lock, _) => ButtonWidget(
                      height: h,
                      onTap: () {
                        if (lock.enabled) {
                          AppLockOptionsDialog().open();
                        } else {
                          AppLockChooserDialog().open();
                        }
                      },
                      label: !lock.enabled
                          ? 'App lock: OFF'
                          : lock.method == LockMethod.device
                              ? 'App lock: Phone unlock'
                              : 'App lock: PIN',
                      color: lock.enabled ? c.accent : c.neutralFill,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  FutureBuilder<int>(
                    future: SessionRepository.instance.count(),
                    builder: (_, snapshot) => Text(
                      'Sessions saved privately on this phone: '
                      '${snapshot.data ?? 0}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 26.t, color: c.textMute),
                    ),
                  ),
                  TextButton(
                    onPressed: () => AboutFidgyDialog().open(),
                    child: Text(
                      'About and privacy',
                      style: TextStyle(
                        fontSize: 28.t,
                        fontWeight: FontWeight.w500,
                        color: c.accent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
}
