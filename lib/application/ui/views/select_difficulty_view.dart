import 'package:flutter/material.dart';

import '../../../common/presentation/presentation.dart';
import '../../domain/game_config.dart';
import '../../domain/general_manager.dart';
import '../components/button_widget.dart';
import '../components/circle_icon_button.dart';
import '../components/header_widget.dart';

class SelectDifficultyView extends StatelessWidget {
  const SelectDifficultyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const HomeHeader(),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ButtonWidget(
                        onTap: () =>
                            GeneralManager.i.selectDifficulty(Difficulty.easy),
                        label: 'Easy',
                        color: AppColors.of(context).mainGreen,
                      ),
                      SizedBox(height: 48.h),
                      ButtonWidget(
                        onTap: () => GeneralManager.i
                            .selectDifficulty(Difficulty.normal),
                        label: 'Normal',
                        color: AppColors.of(context).mainBlue,
                      ),
                      SizedBox(height: 48.h),
                      ButtonWidget(
                        onTap: () =>
                            GeneralManager.i.selectDifficulty(Difficulty.hard),
                        label: 'Hard',
                        color: AppColors.of(context).mainYellow,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 48.r,
                  left: 48.r,
                  child: CircleIconButton(
                    icon: Icons.home_rounded,
                    onTap: GeneralManager.i.goHome,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
