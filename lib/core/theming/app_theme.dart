import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(AppColors.light, Brightness.light);
  static ThemeData get dark => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: 'Poppins',
    );

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.mainGreen,
      onSecondary: c.onColor(c.mainGreen),
      error: c.mainRed,
      onError: c.onColor(c.mainRed),
      surface: c.surface,
      onSurface: c.textStrong,
    );

    final textTheme = base.textTheme.apply(
      bodyColor: c.textStrong,
      displayColor: c.textStrong,
    );

    return base.copyWith(
      colorScheme: scheme,
      extensions: [c],
      scaffoldBackgroundColor: c.backgroundColor,
      canvasColor: c.backgroundColor,
      dividerColor: c.outline,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
    );
  }
}
