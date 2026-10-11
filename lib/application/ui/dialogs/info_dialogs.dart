import 'package:flutter/material.dart';

import '../../../common/presentation/presentation.dart';
import '../../../utilities/constants/constants.dart';
import '../../domain/app_settings.dart';
import '../components/button_widget.dart';
import '../components/mydialog.dart';

const _purpose =
    'Fidgy is a hand training game. It is not a medical device and does not '
    'diagnose, treat or monitor any condition. Talk to your doctor or '
    'therapist before starting a new exercise routine, and stop if anything '
    'hurts or feels wrong.';

const _privacy =
    'Everything you do in Fidgy stays on this phone, stored encrypted. '
    'Nothing is sent anywhere unless you choose to export it.';

/// Shown once, the first time the app opens.
class WelcomeDialog extends AppDialog {
  WelcomeDialog({super.key})
      : super(
          heading: 'Welcome to Fidgy',
          onClose: () {
            AppSettings.i.markWelcomeSeen();
            AppNavigator.main.pop();
          },
          builder: (ctx) {
            final c = AppColors.of(ctx);
            return Column(
              children: [
                SizedBox(
                  width: 700.r,
                  child: Text(
                    _purpose,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32.t, color: c.textMedium),
                  ),
                ),
                SizedBox(height: 24.h),
                SizedBox(
                  width: 700.r,
                  child: Text(
                    _privacy,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32.t, color: c.textStrong),
                  ),
                ),
                SizedBox(height: 40.h),
                ButtonWidget(
                  height: 110.r,
                  onTap: () {
                    AppSettings.i.markWelcomeSeen();
                    AppNavigator.of(ctx).pop();
                  },
                  label: 'I understand',
                ),
              ],
            );
          },
        );
}

/// Version, purpose and privacy in one place (opened from Settings).
class AboutFidgyDialog extends AppDialog {
  AboutFidgyDialog({super.key})
      : super(
          heading: 'About Fidgy',
          builder: (ctx) {
            final c = AppColors.of(ctx);
            return Column(
              children: [
                Text(
                  'Version ${Constants.appVersion}',
                  style: TextStyle(fontSize: 30.t, color: c.textMute),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: 700.r,
                  child: Text(
                    _purpose,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30.t, color: c.textMedium),
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: 700.r,
                  child: Text(
                    _privacy,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30.t, color: c.textStrong),
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: 700.r,
                  child: Text(
                    'You can export your results or delete everything at any '
                    'time from the My progress screen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28.t, color: c.textMute),
                  ),
                ),
              ],
            );
          },
        );
}
