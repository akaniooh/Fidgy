import 'package:flutter/widgets.dart';

import '../../../common/presentation/presentation.dart';
import '../../domain/general_manager.dart';
import '../components/button_widget.dart';
import '../components/mydialog.dart';

class GameOverDialog extends AppDialog {
  factory GameOverDialog.timeUp() => GameOverDialog(
        message: 'You did not complete the level in time',
      );

  factory GameOverDialog.outOfLives() => GameOverDialog(
        message: 'You have exhausted your game lives ❤️',
      );

  GameOverDialog({super.key, required String message})
      : super(
          heading: 'Game over 🚩',
          onClose: GeneralManager.i.goHome,
          builder: (context) => Column(
            children: [
              Text(
                message,
                style: TextStyle(fontSize: 40.t),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48.h),
              ButtonWidget(
                onTap: GeneralManager.i.replayLevel, 
                label: 'Try Again',
                color: AppColors.of(context).mainGreen,
              ),
              SizedBox(height: 48.h),
              ButtonWidget(
                onTap: GeneralManager.i.goHome,
                label: 'Go Home',
                color: AppColors.of(context).neutralFill,
              ),
            ],
          ),
        );
}
