import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../common/presentation/presentation.dart';
import '../../domain/game_data.dart';
import 'home_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    GameData.i.initialise();
    _startSplashTimer();
    super.initState();
  }

  void _startSplashTimer() {
    Future.delayed(const Duration(seconds: 4), () {
      AppNavigator.main.push(const HomeView());
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: c.isDark
                ? const [Color(0xFF0A101E), Color(0xFF14233F)]
                : const [Color(0xFFF3F7FA), Color(0xFFD9ECEF)],
          ),
        ),
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'fidgy'),
                    TextSpan(text: '.', style: TextStyle(color: c.accent)),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 150.t,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -3,
                  color: c.textStrong,
                ),
              )
                  .animate()
                  .fadeIn(duration: 900.milliseconds)
                  .slideY(
                    begin: 0.08,
                    end: 0,
                    duration: 900.milliseconds,
                    curve: Curves.easeOutCubic,
                  )
                  .then()
                  .shake(
                    curve: Curves.easeOutQuad,
                    duration: 2.seconds,
                    hz: 1,
                  ),
              SizedBox(height: 8.h),
              Text(
                'HAND TRAINING',
                style: TextStyle(
                  fontSize: 30.t,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 8,
                  color: c.textMute,
                ),
              ).animate().fadeIn(delay: 600.milliseconds, duration: 800.milliseconds),
            ],
          ),
        ),
      ),
    );
  }
}
