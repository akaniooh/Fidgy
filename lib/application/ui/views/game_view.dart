import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../common/presentation/presentation.dart';
import '../../domain/game_clock.dart';
import '../../domain/game_config.dart';
import '../../domain/game_controller.dart';
import '../components/button_widget.dart';

class GameView extends StatelessWidget {
  const GameView(this.game, {super.key});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    return AppViewBuilder(
      model: game,
      initState: (vm) => vm.startPlaying(),
      builder: (game, _) => Scaffold(
        body: Column(
          children: [
            Container(
              height: 128.h,
              padding: EdgeInsets.symmetric(
                horizontal: 80.r,
                vertical: 16.r,
              ),
              decoration: BoxDecoration(
                color: AppColors.of(context).surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.of(context).outline),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LivesMeter(
                    remainingLives: game.remainingLives,
                    maxLives: game.numberOfLives,
                  ),
                  ProgressMeter(
                    levelVm: game,
                  ),
                  TimerDisplay(game.clock),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  // Raw pointer-down is used instead of onTap so that a hand
                  // that drifts during a press still registers the touch.
                  Positioned.fill(
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (e) =>
                          game.pointerDown(e.pointer, e.position),
                      onPointerUp: (e) => game.pointerUp(e.pointer),
                      onPointerCancel: (e) => game.pointerUp(e.pointer),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: const Alignment(0, -0.2),
                                  radius: 1.1,
                                  colors: [
                                    AppColors.of(context).surface,
                                    AppColors.of(context).backgroundColor,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          for (final finger in Finger.values)
                            Positioned(
                              top: finger.topPosition,
                              left: finger.leftPosition(game.config.hand),
                              child: FingerField(
                                finger,
                                highlight: finger == game.fingerToTap,
                                circleKey: game.fingerKeys[finger]!,
                                scale: game.config.assist.visualScale,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom centre is clear of every finger and the Finish button.
                  Positioned(
                    bottom: 36.r,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: StreakChip(
                          streak: game.streak,
                          target: game.config.criticalStreak,
                        ),
                      ),
                    ),
                  ),
                  if (game.criticalFlash)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CriticalHitOverlay(
                          key: ValueKey(game.criticalPulse),
                        ),
                      ),
                    ),
                  // Sits above the play area so pressing Finish is never
                  // counted as a wrong tap.
                  Positioned(
                    bottom: 48.r,
                    left: 48.r,
                    height: 80.r,
                    width: 250.w,
                    child: ButtonWidget(
                      onTap: game.finish,
                      label: 'Finish',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LivesMeter extends StatelessWidget {
  const LivesMeter({
    super.key,
    required this.remainingLives,
    required this.maxLives,
  });
  final int remainingLives;
  final int maxLives;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < maxLives; i++)
          Icon(
            Icons.favorite_rounded,
            size: 64.r,
            color: AppColors.of(context).mainRed,
          )
              .animate(target: i < remainingLives ? 0 : 1)
              .scale(
                  duration: 1.seconds,
                  curve: Curves.bounceOut,
                  begin: const Offset(1, 1),
                  end: const Offset(1.4, 1.4))
              .fadeOut(begin: 1)
              .then()
              .swap(
                duration: 50.milliseconds,
                builder: (_, __) => Icon(
                  Icons.favorite_border_rounded,
                  size: 64.r,
                  color: AppColors.of(context).textMute,
                ),
              ),
      ],
    );
  }
}

class ProgressMeter extends StatelessWidget {
  const ProgressMeter({
    super.key,
    required this.levelVm,
  });

  final GameController levelVm;

  double _starPosition(double width) {
    final starRange = (levelVm.maxScore - levelVm.firstStarScore) / 2;
    final adjustedStarNumber = levelVm.numberOfStars - 1;
    final starScore = levelVm.firstStarScore + (adjustedStarNumber * starRange);
    final starPosition = (starScore / levelVm.maxScore) * (width - 32.r);
    return starPosition;
  }

  @override
  Widget build(BuildContext context) {
    final width = 390.w;
    final height = 72.r;

    return SizedBox(
      height: height,
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36.r),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.of(context).neutralFill,
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.of(context).mainGreen,
                  borderRadius: BorderRadius.circular(36.r),
                ),
              )
                  .animate(target: levelVm.currentRawScore / levelVm.maxScore)
                  .scaleX(
                    begin: 0.1,
                    duration: 15.seconds,
                    alignment: Alignment.centerLeft,
                    curve: null,
                  ),
            ),
            // Moving star
            if (levelVm.numberOfStars != 0)
              Positioned(
                left: _starPosition(width),
                child: Icon(
                  Icons.star_rounded,
                  size: 64.r,
                  color: switch (levelVm.numberOfStars) {
                    >= 3 => AppColors.of(context).mainGreen,
                    == 2 => AppColors.of(context).mainBlue,
                    <= 1 => AppColors.of(context).mainOrange,
                    _ => null,
                  },
                ),
              ),

            // Star point markers
            if (levelVm.numberOfStars != 1)
              Positioned(
                left: (levelVm.firstStarScore / levelVm.maxScore) * width,
                child: Container(
                  width: 10.w,
                  height: height,
                  color: AppColors.of(context).mainOrange,
                ),
              ),
            if (levelVm.numberOfStars != 2)
              Positioned(
                left: (levelVm.secondStarScore / levelVm.maxScore) * width,
                child: Container(
                  width: 10.w,
                  height: height,
                  color: AppColors.of(context).mainBlue,
                ),
              ),
            if (levelVm.numberOfStars != 3)
              Positioned(
                right: 0,
                child: Container(
                  width: 10.w,
                  height: height,
                  color: AppColors.of(context).mainYellow,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TimerDisplay extends StatelessWidget {
  const TimerDisplay(this.timer, {super.key});
  final GameClock timer;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200.w,
      child: ValueListenableBuilder(
        valueListenable: timer,
        builder: (_, timeLeft, __) => Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              timeLeft,
              style: TextStyle(
                fontSize: 54.t,
                fontWeight: FontWeight.w600,
                color: timer.passedWarningPoint
                    ? AppColors.of(context).mainRed
                    : AppColors.of(context).textStrong,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class FingerField extends StatelessWidget {
  const FingerField(
    this.finger, {
    super.key,
    required this.highlight,
    required this.circleKey,
    this.scale = 1.0,
  });

  final Finger finger;
  final bool highlight;
  final GlobalKey circleKey;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // Taps are resolved centrally by GameController.handleTap, so this
    // widget only draws the finger.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          finger.name,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 32.t,
            fontWeight: FontWeight.w500,
            color: highlight ? c.textStrong : c.textMedium,
          ),
        ),
        const SizedBox(height: 16),
        Animate(
          effects: highlight
              ? [
                  ScaleEffect(
                    duration: 2.5.seconds,
                    begin: const Offset(0.8, 0.8),
                    end: const Offset(1.2, 1.2),
                    curve: Curves.bounceOut,
                  ),
                  ShimmerEffect(
                    duration: 8.seconds,
                    curve: Curves.bounceInOut,
                  ),
                ]
              : null,
          child: Container(
            key: circleKey,
            height: 150.r * scale,
            width: 150.r * scale,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: highlight ? c.accent : c.neutralFill,
              border: Border.all(
                color: highlight ? c.surface : c.outline,
                width: 3.r.clamp(0.4, 3.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: highlight
                      ? c.accent.withValues(alpha: c.isDark ? 0.55 : 0.35)
                      : c.shadow,
                  blurRadius: highlight ? 36 : 14,
                  spreadRadius: highlight ? 4 : 0,
                  offset: highlight ? Offset.zero : const Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

extension FingerScreenPositions on Finger {
  double get topPosition => switch (this) {
        Finger.thumb => 505.h,
        Finger.pointing => 130.h,
        Finger.middle => 21.h,
        Finger.ring => 93.h,
        Finger.pinky => 193.h,
      };

  static final leftPositions = [280.w, 457.w, 642.w, 826.w, 1009.w];
  double leftPosition(Hand hand) {
    final pos = hand == Hand.right ? leftPositions : leftPositions.reversed;
    return pos.elementAt(index);
  }
}

/// Shows progress towards the next critical hit.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.streak, required this.target});

  final int streak;
  final int target;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final near = target > 0 && streak / target >= 0.6;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(horizontal: 28.r, vertical: 10.r),
      decoration: BoxDecoration(
        color: near ? c.mainOrange.withValues(alpha: 0.18) : c.surface,
        borderRadius: BorderRadius.circular(40.r),
        border: Border.all(color: near ? c.mainOrange : c.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 44.r,
            color: streak > 0 ? c.mainOrange : c.textMute,
          ),
          SizedBox(width: 12.r),
          Text(
            '$streak / $target',
            style: TextStyle(
              fontSize: 36.t,
              fontWeight: FontWeight.w600,
              color: c.textStrong,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen celebration when a critical hit lands.
class CriticalHitOverlay extends StatelessWidget {
  const CriticalHitOverlay({super.key});

  static const _sparks = [
    Offset(1, 0),
    Offset(0.7, 0.7),
    Offset(0, 1),
    Offset(-0.7, 0.7),
    Offset(-1, 0),
    Offset(-0.7, -0.7),
    Offset(0, -1),
    Offset(0.7, -0.7),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Stack(
      children: [
        // Warm glow around the edges of the screen.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.95,
                colors: [
                  Colors.transparent,
                  c.mainOrange.withValues(alpha: 0.4),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 200.milliseconds)
              .then(delay: 900.milliseconds)
              .fadeOut(duration: 550.milliseconds),
        ),
        for (final s in _sparks)
          Center(
            child: Container(
              width: 22.r,
              height: 22.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.mainYellow,
                boxShadow: [
                  BoxShadow(
                    color: c.mainOrange.withValues(alpha: 0.8),
                    blurRadius: 14,
                  ),
                ],
              ),
            )
                .animate()
                .move(
                  begin: Offset.zero,
                  end: Offset(s.dx * 420.r, s.dy * 280.r),
                  duration: 800.milliseconds,
                  curve: Curves.easeOutCubic,
                )
                .fadeOut(delay: 300.milliseconds, duration: 500.milliseconds),
          ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                size: 220.r,
                color: c.mainOrange,
                shadows: [
                  Shadow(
                    color: c.mainOrange.withValues(alpha: 0.7),
                    blurRadius: 40,
                  ),
                ],
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.2, 0.2),
                    end: const Offset(1, 1),
                    duration: 550.milliseconds,
                    curve: Curves.elasticOut,
                  )
                  .then(delay: 650.milliseconds)
                  .fadeOut(duration: 350.milliseconds),
              Text(
                'Critical hit!',
                style: TextStyle(
                  fontSize: 84.t,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: c.mainOrange,
                  shadows: [
                    Shadow(
                      color: c.mainOrange.withValues(alpha: 0.6),
                      blurRadius: 30,
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 250.milliseconds)
                  .slideY(begin: 0.4, end: 0, curve: Curves.easeOutBack)
                  .then(delay: 800.milliseconds)
                  .fadeOut(duration: 400.milliseconds),
            ],
          ),
        ),
      ],
    );
  }
}
