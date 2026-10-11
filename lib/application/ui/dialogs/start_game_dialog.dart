import 'package:flutter/material.dart';

import '../../../common/presentation/presentation.dart';
import '../../domain/general_manager.dart';
import '../components/button_widget.dart';
import '../components/mydialog.dart';

class StartGameDialog extends AppDialog {
  StartGameDialog(VoidCallback startGame, {super.key})
      : super(
          heading: 'Ready?',
          builder:(ctx)=> Column(
            children: [
              ButtonWidget(
                onTap: startGame,
                label: 'Begin',
                color: AppColors.of(ctx).mainGreen,
              ),
              SizedBox(height: 56.h),
              ButtonWidget(
                onTap: GeneralManager.i.goHome,
                label: 'Close',
                color: AppColors.of(ctx).neutralFill,
              ),
            ],
          ),
        );
}
