import 'package:flutter/material.dart';

/// Colour tokens for both themes.
///
/// Light  = "calm clinical": cool whites with a deep teal accent.
/// Dark   = "dark premium":  deep navy with a mint accent.
///
/// Older code refers to [mainBlue] as the accent, so it is kept and
/// [accent] is an alias for it.
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.isDark,
    required this.backgroundColor,
    required this.surface,
    required this.surfaceAlt,
    required this.outline,
    required this.neutralFill,
    required this.textStrong,
    required this.textMedium,
    required this.textMute,
    required this.mainBlue,
    required this.mainGreen,
    required this.mainOrange,
    required this.mainYellow,
    required this.mainRed,
    required this.shadow,
  });

  final bool isDark;

  /// Page background.
  final Color backgroundColor;

  /// Cards, dialogs, bars.
  final Color surface;

  /// Chips and secondary panels sitting on a surface.
  final Color surfaceAlt;

  /// Hairline borders and dividers.
  final Color outline;

  /// Inactive / neutral fills (inactive finger, "off" buttons, tracks).
  final Color neutralFill;

  /// Primary text.
  final Color textStrong;

  /// Secondary text.
  final Color textMedium;

  /// Hints and disabled text.
  final Color textMute;

  /// The accent colour.
  final Color mainBlue;
  final Color mainGreen;
  final Color mainOrange;
  final Color mainYellow;
  final Color mainRed;

  /// Soft drop-shadow colour.
  final Color shadow;

  Color get accent => mainBlue;
  Color get onAccent => onColor(mainBlue);

  /// Readable text colour (white or near-black) for content drawn on [fill].
  Color onColor(Color fill) {
    const dark = Color(0xFF0A1220);
    const light = Colors.white;
    double contrast(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      final hi = la > lb ? la : lb;
      final lo = la > lb ? lb : la;
      return (hi + 0.05) / (lo + 0.05);
    }

    return contrast(fill, light) >= contrast(fill, dark) ? light : dark;
  }

  static AppColors of(BuildContext context) {
    final theme = Theme.of(context).extension<AppColors>();
    if (theme == null) {
      throw Exception('AppColors has not been added to app theme extensions');
    }
    return theme;
  }

  static const light = AppColors(
    isDark: false,
    backgroundColor: Color(0xFFF3F7FA),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE9F0F4),
    outline: Color(0xFFD5E0E6),
    neutralFill: Color(0xFFDCE6EB),
    textStrong: Color(0xFF11303B),
    textMedium: Color(0xFF4B6470),
    textMute: Color(0xFF8296A1),
    mainBlue: Color(0xFF0B7A85),
    mainGreen: Color(0xFF15855A),
    mainOrange: Color(0xFFD97B0D),
    mainYellow: Color(0xFFE2AE1B),
    mainRed: Color(0xFFC9363F),
    shadow: Color(0x2211303B),
  );

  static const dark = AppColors(
    isDark: true,
    backgroundColor: Color(0xFF0A101E),
    surface: Color(0xFF111A2E),
    surfaceAlt: Color(0xFF17233D),
    outline: Color(0xFF26355A),
    neutralFill: Color(0xFF1D2A48),
    textStrong: Color(0xFFEAF1FF),
    textMedium: Color(0xFFA7B6D0),
    textMute: Color(0xFF6F81A3),
    mainBlue: Color(0xFF2EE6C5),
    mainGreen: Color(0xFF3DDC97),
    mainOrange: Color(0xFFFFB454),
    mainYellow: Color(0xFFFFD76B),
    mainRed: Color(0xFFFF6B7A),
    shadow: Color(0x66000000),
  );

  @override
  AppColors copyWith({
    bool? isDark,
    Color? backgroundColor,
    Color? surface,
    Color? surfaceAlt,
    Color? outline,
    Color? neutralFill,
    Color? textStrong,
    Color? textMedium,
    Color? textMute,
    Color? mainBlue,
    Color? mainGreen,
    Color? mainOrange,
    Color? mainYellow,
    Color? mainRed,
    Color? shadow,
  }) {
    return AppColors(
      isDark: isDark ?? this.isDark,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      outline: outline ?? this.outline,
      neutralFill: neutralFill ?? this.neutralFill,
      textStrong: textStrong ?? this.textStrong,
      textMedium: textMedium ?? this.textMedium,
      textMute: textMute ?? this.textMute,
      mainBlue: mainBlue ?? this.mainBlue,
      mainGreen: mainGreen ?? this.mainGreen,
      mainOrange: mainOrange ?? this.mainOrange,
      mainYellow: mainYellow ?? this.mainYellow,
      mainRed: mainRed ?? this.mainRed,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(covariant AppColors? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      isDark: t < 0.5 ? isDark : other.isDark,
      backgroundColor: mix(backgroundColor, other.backgroundColor),
      surface: mix(surface, other.surface),
      surfaceAlt: mix(surfaceAlt, other.surfaceAlt),
      outline: mix(outline, other.outline),
      neutralFill: mix(neutralFill, other.neutralFill),
      textStrong: mix(textStrong, other.textStrong),
      textMedium: mix(textMedium, other.textMedium),
      textMute: mix(textMute, other.textMute),
      mainBlue: mix(mainBlue, other.mainBlue),
      mainGreen: mix(mainGreen, other.mainGreen),
      mainOrange: mix(mainOrange, other.mainOrange),
      mainYellow: mix(mainYellow, other.mainYellow),
      mainRed: mix(mainRed, other.mainRed),
      shadow: mix(shadow, other.shadow),
    );
  }
}
