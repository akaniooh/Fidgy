import 'package:flutter/widgets.dart';

import '../../../common/presentation/presentation.dart';
import '../../domain/game_controller.dart';
import '../../domain/general_manager.dart';
import '../components/button_widget.dart';
import '../components/mydialog.dart';

class LevelCompletedDialog extends AppDialog {
  LevelCompletedDialog({super.key, required GameController levelVm})
      : super(
          heading: '🎉 Level Completed',
          onClose: GeneralManager.i.goHome,
          builder: (context) {
            final game = levelVm.config;
            return Column(
              children: [
                Text(
                  'Score - ${levelVm.displayScore} ${'⭐️' * levelVm.numberOfStars}',
                ),
                SizedBox(height: 40.h),
                Text(
                  'Difficulty: ${game.difficulty.name} | '
                  'Level: ${game.level} | '
                  'Hand: ${game.hand.description}',
                ),
                ButtonWidget(
                  onTap: GeneralManager.i.nextLevel,
                  label: 'Next Level',
                  color: AppColors.of(context).mainGreen,
                ),
                SizedBox(height: 48.h),
                ButtonWidget(
                  onTap: GeneralManager.i.replayLevel,
                  label: 'Replay this level',
                  color: AppColors.of(context).neutralFill,
                ),
              ],
            );
          },
        );

  LevelCompletedDialog.timeUp({super.key, required GameController levelVm})
      : super(
          heading: '🎉 Level Completed',
          onClose: GeneralManager.i.goHome,
          builder: (context) {
            final game = levelVm.config;
            return Column(
              children: [
                Text('Score - ${levelVm.displayScore}'),
                SizedBox(height: 40.h),
                Text(
                  'Difficulty: ${game.difficulty.name} | '
                  'Level: ${game.level} | '
                  'Hand: ${game.hand.description}',
                ),
                SizedBox(height: 48.h),
                ButtonWidget(
                  onTap: GeneralManager.i.nextLevel,
                  label: 'Next Level',
                  color: AppColors.of(context).mainGreen,
                ),
                SizedBox(height: 48.h),
                ButtonWidget(
                  onTap: GeneralManager.i.replayLevel,
                  label: 'Replay this level',
                  color: AppColors.of(context).neutralFill,
                ),
              ],
            );
          },
        );
}
