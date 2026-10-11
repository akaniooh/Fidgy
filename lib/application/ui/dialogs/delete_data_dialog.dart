import 'package:flutter/material.dart';

import '../../../common/presentation/presentation.dart';
import '../components/button_widget.dart';
import '../components/mydialog.dart';

class DeleteDataDialog extends AppDialog {
  DeleteDataDialog({super.key, required VoidCallback onConfirmed})
      : super(
          heading: 'Delete all data?',
          builder: (ctx) {
            final c = AppColors.of(ctx);
            return Column(
              children: [
                SizedBox(
                  width: 700.r,
                  child: Text(
                    'This permanently removes every saved session, your '
                    'scores, unlocked levels and critical hits from this '
                    'phone. It cannot be undone. Files you already exported '
                    'are not affected.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 34.t, color: c.textMedium),
                  ),
                ),
                SizedBox(height: 48.h),
                ButtonWidget(
                  onTap: () {
                    AppNavigator.of(ctx).pop();
                    onConfirmed();
                  },
                  label: 'Delete everything',
                  color: c.mainRed,
                ),
                SizedBox(height: 28.h),
                ButtonWidget(
                  onTap: AppNavigator.of(ctx).pop,
                  label: 'Cancel',
                  color: c.neutralFill,
                ),
              ],
            );
          },
        );
}
