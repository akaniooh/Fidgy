import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/svg.dart';

import '../../../common/presentation/presentation.dart';
import '../../domain/app_settings.dart';
import '../../domain/general_manager.dart';
import '../components/button_widget.dart';
import '../components/daily_goal_widgets.dart';
import '../components/header_widget.dart';
import '../dialogs/info_dialogs.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  void initState() {
    super.initState();
    // First launch only: show the welcome notice once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AppSettings.i.welcomeSeen) WelcomeDialog().open();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      body: Column(
        children: [
          // Header
          const HomeHeader(),
          // Gentle suggestion (only when there is one)
          const SuggestionBanner(),
          // Body
          Expanded(
            // Scales the content down if the screen is short, so it can never
            // overflow.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 16.h),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Soft glow behind the hands.
                    Container(
                      width: 1000.w,
                      height: 400.h,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            c.accent.withValues(alpha: c.isDark ? 0.22 : 0.12),
                            c.accent.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/hand_left.svg',
                          height: 320.h,
                        ).animate().shake(
                              hz: 0.5,
                              curve: Curves.easeOut,
                              duration: 3.seconds,
                            ),
                        SizedBox(width: 56.w),
                        SvgPicture.asset(
                          'assets/hand_right.svg',
                          height: 320.h,
                        ).animate().shake(
                              hz: 0.8,
                              delay: 0.5.seconds,
                              curve: Curves.easeOut,
                              duration: 3.seconds,
                            ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 32.h),
                ButtonWidget(
                  height: 120.r,
                  onTap: GeneralManager.i.play,
                  label: 'PLAY',
                ),
                SizedBox(height: 24.h),
                const DailyGoalRow(),
                SizedBox(height: 24.h),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
