import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';

import '../../../common/presentation/presentation.dart';
import '../../domain/game_config.dart';
import '../../domain/general_manager.dart';
import '../components/circle_icon_button.dart';
import '../components/header_widget.dart';

class SelectHandView extends StatelessWidget {
  const SelectHandView({super.key});

  @override
  Widget build(BuildContext context) {
    final rand = Random().nextBool();
    final delayedHand = rand ? Hand.left : Hand.right;

    return Scaffold(
      body: Column(
        children: [
          const HomeHeader(),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  bottom: 80.h,
                  top: 80.h,
                  left: 200.w,
                  right: 200.w,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (final hand in Hand.values)
                        Flexible(
                          child: _HandAndLabel(
                            hand,
                            delayFlag: hand == delayedHand,
                            onTap: () => GeneralManager.i.selectHand(hand),
                          ),
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

class _HandAndLabel extends StatelessWidget {
  const _HandAndLabel(
    this.hand, {
    required this.onTap,
    required this.delayFlag,
  });
  final Hand hand;
  final VoidCallback onTap;
  final bool delayFlag;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () => GeneralManager.i.selectHand(hand),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: SvgPicture.asset(
              'assets/hand_${hand.name}.svg',
            ),
          ).animate().scale(
                delay: delayFlag ? 0.8.seconds : null,
                curve: Curves.bounceOut,
                duration: 3.seconds,
                begin: const Offset(.8, .8),
              ),
          Text(
            hand.description,
            style: TextStyle(
              fontSize: 54.t,
              fontWeight: FontWeight.w500,
              color: AppColors.of(context).textStrong,
            ),
          ),
        ],
      ),
    );
  }
}
